class AccessionsController <  ApplicationController
  include TreeApis

  skip_before_filter  :verify_authenticity_token

  DEFAULT_AC_TYPES = %w{accession}
  DEFAULT_AC_FACET_TYPES = %w{primary_type subjects agents repository}
  DEFAULT_AC_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'resolve[]' => ['repository:id', 'resource:id@compact_resource'],
    'facet.mincount' => 1
  }
  DEFAULT_AC_SEARCH_PARAMS = {
    :q => ['*'],
    :limit => 'accession',
    :op => ['OR'],
    :field => ['title']
  }
  def index
    if !params.fetch(:q, nil)
      DEFAULT_AC_SEARCH_PARAMS.each do |k, v|
        params[k] = v
      end
    end
    @base_search = '/accessions?'
    page = Integer(params.fetch(:page, "1"))
    search_opts = default_search_opts( DEFAULT_AC_SEARCH_OPTS)
    begin
      set_up_and_run_search( DEFAULT_AC_TYPES, DEFAULT_AC_FACET_TYPES,  search_opts, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/') and return
    end
#    @context = repo_context(repo_id, 'accession')
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

    @page_title = I18n.t('accession._plural')
    @results_type = @page_title
    @no_statement = true
    render 'search/search_results'

  end

  def search
      # need at least q[]=WHATEVER&op[]=OR&field[]=title&from_year[]=&to_year[]=&limit=accession
    @base_search = '/accessions/search?'
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search( DEFAULT_AC_TYPES, DEFAULT_AC_FACET_TYPES,  DEFAULT_AC_SEARCH_OPTS, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/') and return
    end
    @page_title = I18n.t('accession._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('accession._plural'), :term => params.fetch(:q)[0]})
     render 'search/search_results'
  end

  def show
    uri = "/repositories/#{params[:rid]}/accessions/#{params[:id]}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    @results =  archivesspace.search_records([uri],1,@criteria)
    @results =  handle_results(@results)
    if !@results['results'].blank? && @results['results'].length > 0
      @result = @results['results'][0]
#      Pry::ColorPrinter.pp(@result)
      @page_title = strip_mixed_content(@result['json']['title'])
      @context = []
      @context.unshift({:uri => @result['_resolved_repository']['json']['uri'], :crumb =>  @result['_resolved_repository']['json']['name']})
      @context.push({:uri => '', :crumb => @result['json']['title'] })
    else
      @type = I18n.t('accession._singular')
      @page_title = I18n.t('errors.error_404', :type => @type)
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
end
