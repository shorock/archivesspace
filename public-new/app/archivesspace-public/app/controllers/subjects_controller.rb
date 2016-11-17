class SubjectsController <  ApplicationController

  skip_before_filter  :verify_authenticity_token
  DEFAULT_SUBJ_TYPES = %w{repository resource archival_object digital_object}
  DEFAULT_SUBJ_FACET_TYPES = %w{primary_type agents}
  DEFAULT_SUBJ_SEARCH_OPTS = {
    'sort' => 'title_sort asc',
    'facet.mincount' => 1
   }

  def index
#    repo_id = params.fetch(:repo_id, nil)
    if params.fetch(:q, nil) 
        pass_params = params
    else
      pass_params = {}
      pass_params[:q] = ['*']
      pass_params[:recordtypes] = ['subject']
      pass_params[:limit] = 'subject'
      pass_params[:field] = ['title']
      pass_params[:op] = ['OR']
    end
    @base_search  =  "/subjects?" # we need to handle repository, but lets hold off on that
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(['subject'],DEFAULT_SUBJ_FACET_TYPES,DEFAULT_SUBJ_SEARCH_OPTS, pass_params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/subjects' ) and return
    end
    @page_title = I18n.t('subject._plural')
    @results_type = @page_title
    render 'search/search_results'
  end

  def search
  # need at least q[]=WHATEVER&op[]=OR&field[]=title&from_year[]=&to_year[]=&limit=subject
     @base_search  =  "/subjects/search?"
    page = Integer(params.fetch(:page, "1"))
    begin
      set_up_and_run_search(['subject'],DEFAULT_SUBJ_FACET_TYPES,DEFAULT_SUBJ_SEARCH_OPTS, params)
    rescue Exception => error
      flash[:error] = error
      redirect_back(fallback_location: '/subjects' ) and return
    end
    @page_title = I18n.t('subject._plural')
    @results_type = @page_title
    @search_title = I18n.t('search_results.search_for', {:type => I18n.t('subject._plural'), :term => params.fetch(:q)[0]})
    render 'search/search_results'
  end

  def show
    sid = params.require(:id)
    uri = "/subjects/#{sid}"
    @criteria = {}
    @criteria['resolve[]']  = ['repository:id', 'resource:id@compact_resource']
    results =  archivesspace.search_records([uri],1,@criteria)
    results =  handle_results(results)
    if !results['results'].blank? && results['results'].length > 0
      @result = results['results'][0]
#      Pry::ColorPrinter.pp(@result)
      @results = fetch_subject_results(@result['title'],uri, params)
      if !@results.blank?
        @pager =  Pager.new(@base_search, @results['this_page'],@results['last_page']) 
      else
        @pager = nil
      end
      @page_title = strip_mixed_content(@result['json']['title']) || "#{I18n.t('subject._singular')} #{uri}"
#      Rails.logger.debug("subject title: #{@page_title}")
      @context = []
    else
      @page_title = I18n.t 'errors.error_404'
      @uri = uri
      @back_url = request.referer || ''
      render  'shared/not_found'
    end
  end
  private 
  
  def fetch_subject_results(title, uri, params)
    @results = []
    qry = "#{params.fetch(:q,'*')} AND subjects:\"#{title}\""
    @base_search = "#{uri}?"
    set_up_search(DEFAULT_SUBJ_TYPES, DEFAULT_SUBJ_FACET_TYPES, DEFAULT_SUBJ_SEARCH_OPTS, params, qry)
    page = Integer(params.fetch(:page, "1"))
    Rails.logger.debug("subject results query: #{@query}")
    @results =  archivesspace.search(@query,page, @criteria)
    if @results['total_hits'] > 0
      process_search_results(@base_search)
    else
      @results = []
    end
    @results
  end
end
