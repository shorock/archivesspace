class ObjectsController <  ApplicationController
  include TreeApis
  include ResultInfo
  helper_method :process_repo_info
  helper_method :process_subjects
  helper_method :process_agents
  helper_method :process_digital
  helper_method :process_digital_instance

  skip_before_filter  :verify_authenticity_token
  
  DEFAULT_OBJ_FACET_TYPES = %w(repository primary_type subjects agents)
  DEFAULT_OBJ_SEARCH_OPTS = {
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1,
    'sort' =>  'title_sort asc'
  }
  
  def index
    repo_id = params.fetch(:rid, nil)
     if !params.fetch(:q,nil)
      params[:q] = ['*']
      params[:limit] = 'digital_object,archival_object' unless params.fetch(:limit,nil)
      params[:op] = ['OR']
    end
    page = Integer(params.fetch(:page, "1"))
    search_opts = default_search_opts(DEFAULT_OBJ_SEARCH_OPTS)
    search_opts['fq'] = ["repository:\"/repositories/#{repo_id}\""] if repo_id
    @base_search = repo_id ? "/repositories/#{repo_id}/objects?" : '/objects?'

    begin
      set_up_and_run_search( params[:limit].split(","), DEFAULT_OBJ_FACET_TYPES, search_opts,params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/') and return
    end
    @context = repo_context(repo_id, 'record')
    unless @pager.one_page?
      @search[:dates_within] = true if params.fetch(:filter_from_year,'').blank? && params.fetch(:filter_to_year,'').blank?
      @search[:text_within] = true
    end
    @sort_opts = []
    all_sorts = Search.get_sort_opts
    all_sorts.delete('relevance') unless params[:q].size > 1 || params[:q] != '*'
    all_sorts.keys.each do |type|
       @sort_opts.push(all_sorts[type])
    end

    @page_title = I18n.t('record._plural')
    @results_type = @page_title
    @no_statement = true
    render 'search/search_results'
  end

  def search
    @base_search  =  "/objects/search?"
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(%w(digital_object archival_object),DEFAULT_OBJ_FACET_TYPES,DEFAULT_OBJ_SEARCH_OPTS, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/objects' ) and return
    end
    @page_title = I18n.t('record._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('record._plural'), :term => params.fetch(:q)[0]})
    @no_statement = true
    render 'search/search_results'
  end

  def request_showing
    @request = RequestItem.new(params)
    # if we got here, we need to know where to go back to
    @back_url =  request.referer || ''
  end

  def show
    uri = "/repositories/#{params[:rid]}/#{params[:obj_type]}/#{params[:id]}"
    url = uri
    if params[:obj_type] == 'archival_objects'
      url = uri += '#pui' if !uri.ends_with?('#pui')
    end
    uri = uri.sub("\#pui",'')
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource', 'top_container_uri_u_sstr:id']
    @result = object_result(url, @criteria)
    if !@result.empty?
      begin
        @repo_info =  process_repo_info(@result)
        @page_title = strip_mixed_content(@result['json']['display_string'] || @result['json']['title'])
        @tree = fetch_tree(uri)
        digital_archival_info(@result['json']) if @result['primary_type'] == 'digital_object'
        @context = breadcrumb_info
        @cite = fill_cite
        @subjects = process_subjects(@result['json']['subjects'])
        @agents = process_agents(@result['json']['linked_agents'], @subjects)
        @dig = process_digital(@result['json'])
        @dig = process_digital_instance(@result['json']['instances']) if @dig.blank?
        fill_request_info unless @result['primary_type'] == 'digital_object'
      rescue Exception => error
        Pry::ColorPrinter.pp error.backtrace
        throw error
      end
      render
    else
      @type = I18n.t("#{(params[:obj_type] == 'archival_objects'? 'archival' : 'digital')}_object._singular")
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end

  private
  # return a single processed archival or digital object
  def object_result(url, criteria)
    result = {}
    results =  archivesspace.search_records([url],1,criteria)
    results = handle_results(results)
    unless results['results'].blank? || results['results'].empty?
      result = results['results'][0]
    end
    result
  end
  
  # get archival info
  def digital_archival_info(dig_json)
    Rails.logger.debug("****\tdigital_archival_info: #{dig_json['linked_instances']}")
    unless dig_json['linked_instances'].empty? || !dig_json['linked_instances'][0].dig('ref')
      uri = dig_json['linked_instances'][0].dig('ref')
      uri << '#pui' unless uri.end_with?('#pui')
      arch = object_result(uri, @criteria)
      unless arch.blank?
        arch['json']['html'].keys.each do |type|
          dig_json['html'][type] = arch['json']['html'][type] if dig_json.dig('html', type).blank?
        end
        @tree = fetch_tree(uri.sub('#pui','')) if @tree['path_to_root'].blank?
      end
    end
  end

end
