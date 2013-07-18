# encoding: UTF-8
# Handle tasks for a Company / User

require 'csv'

class TasksController < ApplicationController
  before_filter :check_if_user_has_projects,    :only => [:new, :create]
  before_filter :check_if_user_can_create_task, :only => [:create]
  before_filter :authorize_user_is_admin, :only => [:planning]

  cache_sweeper :tag_sweeper, :only =>[:create, :update]

  def index
    @task   = TaskRecord.accessed_by(current_user).find_by_id(session[:last_task_id])

    session[:jqgrid_sort_column]= params[:sidx] unless params[:sidx].nil?
    session[:jqgrid_sort_order] = params[:sord] unless params[:sord].nil?
    @tasks = current_task_filter.tasks_for_jqgrid(params)

    @work_log_kinds = WorkLogKind.all

    respond_to do |format|
      format.html
      format.json { render :template => "tasks/index.json"}
    end
  end

  def new
    @task = create_entity
    @task.task_num = nil
    # TODO: Set this default value on the db
    @task.duration = 0
    @task.watchers << current_user

    render 'tasks/new'
  end

  def create
    @task.task_due_calculation(params[:task][:due_at], current_user)
    @task.duration = TimeParser.parse_time(params[:task][:duration])
    @task.duration = 0 if @task.duration.nil?
    if @task.service_id == -1
      @task.isQuoted   = true
      @task.service_id = nil
    else
      @task.isQuoted = false
    end
    params[:todos].collect { |todo| @task.todos.build(todo) } if params[:todos]

    # One task can have two  worklogs, so following code can raise three exceptions
    # ActiveRecord::RecordInvalid or ActiveRecord::RecordNotSaved
    begin
      ActiveRecord::Base.transaction do
        begin
          @task.save!
        rescue ActiveRecord::RecordNotUnique
          @task.save!
        end
        @task.set_users_dependencies_resources(params, current_user)
        files = @task.create_attachments(params['tmp_files'], current_user)
        create_worklogs_for_tasks_create(files) if @task.is_a?(TaskRecord)
      end
      set_last_task(@task)

      flash[:success] ||= (link_to_task(@task) + " - #{_('Task was successfully created.')}")
      Trigger.fire(@task, Trigger::Event::CREATED)
      return if request.xhr?
      redirect_to tasks_path
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      flash[:error] = @task.errors.full_messages.join(". ")
      return if request.xhr?
      render :template => 'tasks/new'
    end
  end

  def calendar
    respond_to do |format|
      format.html
      format.json{
        @tasks = current_task_filter.tasks_for_fullcalendar(params)
      }
    end
  end

  def gantt
    respond_to do |format|
      format.html
      format.json{
        @tasks = current_task_filter.tasks_for_gantt(params)
      }
    end
  end

  def auto_complete_for_dependency_targets
    value = params[:term]
    value.gsub!(/#/, '')
    @keys = [ value ]
    @tasks = TaskRecord.search(current_user, @keys)
    render :json=> @tasks.collect{|task| {:label => "[##{task.task_num}] #{task.name}", :value=>task.name[0..13] + '...' , :id => task.task_num } }.to_json
  end

  def auto_complete_for_resource_name
    return if !current_user.use_resources?

    search = params[:term]
    search = search.split(",").last if search

    if !search.blank?
      conds = "lower(name) like ?"
      cond_params = [ "%#{ search.downcase }%" ]

      # only return resources related to current selected customer
      params[:customer_ids] ||= []
      params[:customer_ids] = [0] if params[:customer_ids].empty?
      conds += "and (customer_id in (?))"
      cond_params << params[:customer_ids]

      conds = [ conds ] + cond_params

      @resources = current_user.company.resources.where(conds)
      render :json=> @resources.collect{|resource| {:label => "[##{resource.id}] #{resource.name}", :value => resource.name, :id=> resource.id} }.to_json
    else
      render :nothing=> true
    end
  end

  def resource
    resource = current_user.company.resources.find(params[:resource_id])
    render(:partial => "resource", :locals => { :resource => resource })
  end

  def dependency
    dependency = TaskRecord.accessed_by(current_user).find_by_task_num(params[:dependency_id])
    render(:partial => "dependency",
           :locals => { :dependency => dependency, :perms => {} })
  end

  def edit
    @task = AbstractTask.accessed_by(current_user).find_by_task_num(params[:id])

    if @task.nil?
      flash[:error] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last
      return
    end

    set_last_task(@task)
    @task.set_task_read(current_user)
    @work_log_kinds = WorkLogKind.all

    respond_to do |format|
      format.html { render :template=> 'tasks/edit'}
      format.js {
        html = render_to_string(:template=>'tasks/edit', :layout => false)
        render :json => { :html => html, :task_num => @task.task_num, :task_name => @task.name }
      }
    end
  end

  def update
    @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    if @task.nil?
      flash[:error] = _("You don't have access to that task, or it doesn't exist.")
      redirect_from_last and return
    end

    # TODO this should be a before_filter
    unless current_user.can?(@task.project,'edit') or current_user.can?(@task.project, 'comment')
      flash[:error] = ProjectPermission.message_for('edit')
      redirect_from_last and return
    end

    # if user only have comment rights
    if current_user.can?(@task.project, 'comment') and !current_user.can?(@task.project,'edit')
      params[:task] = {}
    end

    # TODO this should go into Task model
    begin
      ActiveRecord::Base.transaction do
        TaskRecord.update(@task, params, current_user)
      end

      # TODO this should be an observer
      Trigger.fire(@task, Trigger::Event::UPDATED)
      flash[:success] ||= link_to_task(@task) + " - #{_('Task was successfully updated.')}"

      respond_to do |format|
        format.html { redirect_to :action=> "edit", :id => @task.task_num  }
        format.js {
          render :json => {
            :status => :success,
            :tasknum => @task.task_num,
            :tags => render_to_string(:partial => "tags/panel_list.html.erb"),
            :message => render_to_string(:partial => "layouts/flash.html.erb", :locals => {:flash => flash}).html_safe }
        }

      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      flash[:error] = @task.errors.full_messages.join(". ")
      respond_to do |format|
        format.html { render :template=> 'tasks/edit' }
        format.js { render :json => {:status => :error, :messages => @task.errors.full_messages}.to_json }
      end
    end
  end


  def get_csv
    filename = "jobsworth_tasks.csv"
    @tasks= current_task_filter.tasks
    csv_string = CSV.generate( :col_sep => "," ) do |csv|
      csv << @tasks.first.csv_header
      @tasks.each do |t|
        csv << t.to_csv
      end

    end
    logger.info("Sending[#{filename}]")

    send_data(csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => filename)
  end

  def refresh_service_options
    @task = create_entity
    if params[:taskId]
      @task = AbstractTask.accessed_by(current_user).find(params[:taskId])
    end

    customers = []
    customerIds = []
    customerIds = params[:customerIds].split(',') if params[:customerIds]
    customerIds.each do |cid|
      customers << current_user.company.customers.find(cid)
    end

    render :json => {:success => true, :html => view_context.options_for_task_services(customers, @task) }
  end

  def get_watcher
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    user = current_user.company.users.active.find(params[:user_id])
    @task.task_watchers.build(:user => user)

    render(:partial => "tasks/notification", :locals => { :notification => user })
  end

  def get_customer
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    customer = current_user.company.customers.find(params[:customer_id])
    @task.task_customers.build(:customer => customer)

    render(:partial => "tasks/task_customer", :locals => { :task_customer => customer })
  end

  def get_default_customers
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    @project = current_user.projects.find_by_id(params[:project_id])

    @customers = []
    @customers << @project.customer
    @customers += @task.customers

    render(:partial => "tasks/task_customer", :collection => @customers, :as => :task_customer)
  end

  def get_default_watchers_for_customer
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    if params[:customer_id].present?
      @customer = current_user.company.customers.find(params[:customer_id])
    end

    users = @customer ? @customer.users.auto_add.all : []
    users.reject! {|u| @task.users.include?(u) }

    res = render_to_string(:partial => "tasks/notification", :collection => users)
    render :text => res
  end

  def get_default_watchers
    @task = create_entity
    if !params[:id].blank?
      @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])
    end

    @customers = []
    if params[:customer_ids].present?
      @customers = current_user.company.customers.where("customers.id IN (?)", params[:customer_ids])
    end

    if params[:project_id].present?
      @project = current_user.projects.find_by_id(params[:project_id])
      @customers << @project.customer if @project.try(:customer)
    end

    @users = [current_user]
    @customers.each {|c| @users += c.users.auto_add.all }
    @users += @task.users
    @users.uniq!

    res = render_to_string(:partial => "tasks/notification", :collection => @users)
    render :text => res
  end

  # GET /tasks/billable?customer_ids=:customer_ids&project_id=:project_id&service_id=:service_id
  def billable
    @project = current_user.projects.find(params[:project_id]) if params[:project_id]
    return render :json => {:billable => false} if @project and @project.suppressBilling
    return render :json => {:billable => false} if params[:service_id].to_i < 0
    return render :json => {:billable => true} if params[:service_id].to_i == 0

    @customer_ids = (params[:customer_ids] || "").split(',')
    slas = []
    @customer_ids.each do |cid|
      customer = current_user.company.customers.find(cid) rescue nil

      if customer
        sla = customer.service_level_agreements.where(:service_id => params[:service_id]).first rescue nil
        slas << sla if sla
      end
    end

    sla = slas.detect {|s| s.billable}
    if sla
      return render :json => {:billable => true}
    else
      return render :json => {:billable => false}
    end
  end

  def set_group
    task = TaskRecord.accessed_by(current_user).find_by_task_num(params[:id])
    task.update_group(current_user, params[:group], params[:value], params[:icon])

    expire_fragment( %r{tasks\/#{task.id}-.*\/*} )
    render :nothing => true
  end

  def update_sheet_info
    render :partial => "/layouts/sheet_info"
  end

  def users_to_notify_popup
    # anyone already attached to the task should be removed
    excluded_ids = params[:watcher_ids].blank? ? 0 : params[:watcher_ids]
    @users = current_user.customer.users.active.where("id NOT IN (#{excluded_ids})").order('name').limit(50)
    @task = AbstractTask.accessed_by(current_user).find_by_id(params[:id])

    @task && @task.customers.each do |customer|
      @users = @users + customer.users.active.where("id NOT IN (#{excluded_ids})").order('name').limit(50)
    end
    @users = @users.uniq.sort_by{|user| user.name}.first(50)

    if @task && current_user.customer != @task.project.customer
      @users = @users + @task.project.customer.users.active.where("id NOT IN (#{excluded_ids})")
      @users = @users.uniq.sort_by{|user| user.name}.first(50)
    end
    render :layout =>false
  end

  # The user has dragged a task into a different order and we need to adjust the weight adjustment accordingly
  def change_task_weight
    @user = current_user
    if current_user.admin? and params[:user_id]
      @user = current_user.company.users.find(params[:user_id])
    end

    # Note that we check the user has access to this task before moving it
    moved = TaskRecord.accessed_by(@user).find_by_id(params[:moved])
    return render :json => { :success => false } if moved.nil?

    # If prev is not passed, then the user wanted to move the task to the top of the list
    if (params[:prev])
      prev = TaskRecord.accessed_by(@user).find_by_id(params[:prev])
    end

    if prev.nil?
      topTask = @user.tasks.open_only.not_snoozed.order("weight DESC").first
      changeRequired = topTask.weight - moved.weight + 1
    else
      changeRequired = prev.weight - moved.weight - 1
    end
    moved.weight_adjustment = moved.weight_adjustment + changeRequired
    moved.weight = moved.weight + changeRequired
    moved.save(:validate => false)
    render :json => { :success => true }
  end

  # GET /tasks/planning
  def planning
    @users = current_user.company.users.active.order("name ASC")
    render :layout => "layouts/basic"
  end

  def clone
    @template = current_templates.find_by_task_num(params[:id])
    @task = TaskRecord.new(@template.as_json['template'])
    @task.todos = @template.todos
    @task.customers = @template.customers
    @task.users = @template.users
    @task.watchers = @template.watchers
    @task.owners = @template.owners
    @task.task_property_values = @template.task_property_values
    render 'tasks/new'
  end

  # GET /tasks/score/:id
  def score
    @task = TaskRecord.accessed_by(current_user).find_by_task_num(params[:id])
    if @task.nil?
      flash[:error] = _'Invalid Task Number'
      redirect_to 'index'
    else
      # Force score recalculation
      @task.save(:validation => false)
    end
  end

  # build 'next tasks' panel from an ajax call (click on the more... button)
  def nextTasks
    @user = current_user
    if current_user.admin? and params[:user_id]
      @user = current_user.company.users.find(params[:user_id])
    end

    html = render_to_string :partial => "tasks/next_tasks_panel", :locals => { :count => params[:count].to_i, :user => @user }
    render :json => { :html => html, :has_more => (@user.tasks.open_only.not_snoozed.count > params[:count].to_i) }
  end

  # Relatório antigo

  def filter
    do_filter
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def list
    @tags = {}
    @tags.default = 0
    @tags_total = 0
    if session[:filter_project].to_i == 0
      project_ids = current_project_ids
    else
      project_ids = session[:filter_project]
    end

    filter = ""

    if session[:filter_user].to_i > 0
      task_ids = User.find(session[:filter_user].to_i).tasks.collect { |t| t.id }.join(',')
      if task_ids == ''
        filter = "tasks.id IN (0) AND "
      else
        filter = "tasks.id IN (#{task_ids}) AND "
      end
    elsif session[:filter_user].to_i < 0
      not_task_ids = Task.find(:all, :select => "tasks.*", :joins => "LEFT OUTER JOIN task_owners t_o ON tasks.id = t_o.task_id", :readonly => false, :conditions => ["tasks.company_id = ? AND t_o.id IS NULL", current_user.company_id]).collect { |t| t.id }.join(',')
      if not_task_ids == ''
        filter = "tasks.id = 0 AND "
      else
        filter = "tasks.id IN (#{not_task_ids}) AND " if not_task_ids != ""
      end
    end

    if session[:filter_milestone].to_i > 0
      filter << "tasks.milestone_id = #{session[:filter_milestone]} AND "
    elsif session[:filter_milestone].to_i < 0
      filter << "(tasks.milestone_id IS NULL OR tasks.milestone_id = 0) AND "
    end

    unless session[:filter_status].to_i == -1 || session[:filter_status].to_i == -2
      if session[:filter_status].to_i == 0
        filter << "(tasks.status = 0 OR tasks.status = 1) AND "
      elsif session[:filter_status].to_i == 2
        filter << "(tasks.status > 1) AND "
      else
        filter << "tasks.status = #{session[:filter_status].to_i} AND "
      end
    end

    if session[:filter_status].to_i == -2
      filter << "tasks.hidden = 1 AND "
    else
      filter << "tasks.hidden = 0 AND "
    end

    if session[:hide_deferred].to_i > 0
      filter << "(tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND "
    end

    unless session[:filter_type].to_i == -1
      filter << "tasks.type_id = #{session[:filter_type].to_i} AND "
    end

    unless session[:filter_severity].to_i == -10
      filter << "tasks.severity_id >= #{session[:filter_severity].to_i} AND "
    end

    unless session[:filter_priority].to_i == -10
      filter << "tasks.priority >= #{session[:filter_priority].to_i} AND "
    end

    unless session[:filter_customer].to_i == 0
      filter << "tasks.project_id IN (#{current_user.projects.find(:all, :conditions => ["customer_id = ?", session[:filter_customer]]).collect(&:id).compact.join(',') }) AND "
    end

    completed_milestone_ids_str = "#{completed_milestone_ids}".gsub(/[\[\]]/, '')
    filter << "(tasks.milestone_id NOT IN (#{completed_milestone_ids_str}) OR tasks.milestone_id IS NULL) "

    if params[:tag] && params[:tag].length > 0
      # Looking for tasks based on tags
      @selected_tags = params[:tag].downcase.split(',').collect{|t| t.strip}
      @tasks = AbstractTask.tagged_with(@selected_tags, { :company_id => current_user.company_id, :project_ids => project_ids, :filter_hidden => session[:filter_hidden], :filter_user => session[:filter_user], :filter_milestone => session[:filter_milestone], :filter_status => session[:filter_status], :filter_customer => session[:filter_customer] })
    else
      # Looking for tasks based on filters
      @selected_tags = []
      project_ids_str = "#{project_ids}".gsub(/[\[\]]/, '')
      @tasks = AbstractTask.find(:all, :conditions => "tasks.project_id IN (#{project_ids_str}) AND " + filter, :include => [:users, :tags, :sheets, :todos, :dependencies, {:dependants => [:users, :tags, :sheets, :todos, { :project => :customer }, :milestone]}, { :project => :customer}, :milestone ])
    end

    @tasks = case session[:sort].to_i
             when 0
                 @tasks.sort_by{|t| [-t.completed_at.to_i, t.priority + t.severity_id/2.0, -(t.due_date || 9999999999).to_i, -t.task_num] }.reverse
             when 1
                 @tasks.sort_by{|t| [-t.completed_at.to_i, (t.due_date || 9999999999).to_i, t.priority + t.severity_id/2.0,  -t.task_num] }
             when 2
                 @tasks.sort_by{|t| [-t.completed_at.to_i, t.created_at.to_i, t.priority + t.severity_id/2.0,  -t.task_num] }
             when 3
                 @tasks.sort_by{|t| [-t.completed_at.to_i, t.name.downcase, t.priority + t.severity_id/2.0,  -t.task_num] }
             when 4
                 @tasks.sort_by{|t| [-t.completed_at.to_i, t.updated_at.to_i, t.priority + t.severity_id/2.0,  -t.task_num] }.reverse
             end

    # Most popular tags, currently unlimited.
    # debugger
    user_company = Company.find(current_user.company_id)
    @all_tags = Tag.top_counts(user_company, {:company_id => current_user.company_id, :project_ids => project_ids, :filter_hidden => session[:filter_hidden], :filter_customer => session[:filter_customer]})
    @group_ids = { }
    if session[:group_by].to_i == 1 # tags
      @tag_names = @all_tags.collect{|i,j| i}
      @groups = Task.tag_groups(current_user.company_id, @tag_names, @tasks)
    elsif session[:group_by].to_i == 2 # Clients
      clients = Customer.find(:all, :conditions => ["company_id = ?", current_user.company_id], :order => "name")
      clients.each { |c| @group_ids[c.name] = c.id }
      items = clients.collect(&:name).sort
      @groups = Task.group_by(@tasks, items) { |t,i| t.project.customer.name == i }
    elsif session[:group_by].to_i == 3 # Projects
      projects = current_user.projects
      projects.each { |p| @group_ids[p.full_name] = p.id }
      items = projects.collect(&:full_name).sort
      @groups = Task.group_by(@tasks, items) { |t,i| t.project.full_name == i }
    elsif session[:group_by].to_i == 4 # Milestones
      filter = ""
      if session[:filter_milestone].to_i > 0
        m = Milestone.find(session[:filter_milestone], :conditions => ["project_id IN (#{current_project_ids}) AND completed_at IS NULL"], :order => "due_at, name") rescue nil
        filter = " AND project_id = #{m.project_id}" if m
      elsif session[:filter_project].to_i > 0
        filter = " AND project_id = #{session[:filter_project]}"
      elsif session[:filter_customer].to_i > 0
        pids = current_user.company.customers.find(session[:filter_customer]).projects.collect{|p| p.id}.join(',') rescue '0'
        filter = " AND project_id IN (#{pids})"
      end
      milestones = Milestone.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})#{filter} AND completed_at IS NULL", current_user.company_id], :order => "due_at, name")
      milestones.each { |m| @group_ids[m.name + " / " + m.project.name] = m.id }
      @group_ids['Unassigned'] = 0
      items = ["Unassigned"] +  milestones.collect{ |m| m.name + " / " + m.project.name }
      @groups = Task.group_by(@tasks, items) { |t,i| (t.milestone ? (t.milestone.name + " / " + t.project.name) : "Unassigned" ) == i }
    elsif session[:group_by].to_i == 5 # Users
      users = current_user.company.users
      users.each { |u| @group_ids[u.name] = u.id }
      @group_ids[_('Unassigned')] = 0
      items = [_("Unassigned")] + users.collect(&:name).sort
      @groups = Task.group_by(@tasks, items) { |t,i|
        if t.users.size > 0
          res = t.users.collect(&:name).include? i
        else
          res = (_("Unassigned") == i)
        end
        res
      }
    elsif session[:group_by].to_i == 6 # Task Type
      0.upto(3) { |i| @group_ids[ _(Task.issue_types[i]) ] = i }
      items = Task.issue_types.collect{ |i| _(i) }.sort
      @groups = Task.group_by(@tasks, items) { |t,i| _(t.issue_type) == i }
    elsif session[:group_by].to_i == 7 # Status
      0.upto(5) { |i| @group_ids[ _(Task.status_types[i]) ] = i }
      items = Task.status_types.collect{ |i| _(i) }
      @groups = Task.group_by(@tasks, items) { |t,i| _(t.status_type) == i }
    elsif session[:group_by].to_i == 8 # Severity
      -2.upto(3) { |i| @group_ids[_(Task.severity_types[i])] = i }
      items = Task.severity_types.sort.collect{ |v| _(v[1]) }.reverse
      @groups = Task.group_by(@tasks, items) { |t,i| _(t.severity_type) == i }
    elsif session[:group_by].to_i == 9 # Priority
      -2.upto(3) { |i| @group_ids[ _(Task.priority_types[i])] = i }
      items = Task.priority_types.sort.collect{ |v| _(v[1]) }.reverse
      @groups = Task.group_by(@tasks, items) { |t,i| _(t.priority_type) == i }
    elsif session[:group_by].to_i == 10 # Projects / Milestones
      milestones = Milestone.find(:all, :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND completed_at IS NULL", current_user.company_id], :order => "due_at, name")
      projects = current_user.projects

      milestones.each { |m| @group_ids["#{m.project.name} / #{m.name}"] = "#{m.project_id}_#{m.id}" }
      projects.each { |p| @group_ids["#{p.name}"] = p.id }

      items = milestones.collect{ |m| "#{m.project.name} / #{m.name}" }.flatten
      items += projects.collect(&:name)
      items = items.uniq.sort

      @groups = Task.group_by(@tasks, items) { |t,i| t.milestone ? ("#{t.project.name} / #{t.milestone.name}" == i) : (t.project.name == i)  }
    elsif session[:group_by].to_i == 11 # Requested By
      requested_by = @tasks.collect{|t| t.requested_by.blank? ? nil : t.requested_by }.compact.uniq.sort
      requested_by = [_('No one')] + requested_by
      @groups = Task.group_by(@tasks, requested_by) { |t,i| (t.requested_by.blank? ? _('No one') : t.requested_by) == i }
    else
      @groups = [@tasks]
    end

  end

  # Fim Relatório antigo


  protected

  def check_if_user_can_create_task
    @task = create_entity
    @task.attributes = params[:task]

    unless current_user.can?(@task.project, 'create')
      flash[:error] = _("You don't have access to create tasks on this project.")
      render :new
    end
  end

  def check_if_user_has_projects
    unless current_user.has_projects?
      flash[:error] = _("You need to create a project to hold your tasks.")
      redirect_to new_project_path
    end
  end

  def do_filter

    f = params[:filter]

    if f.nil? || f.empty? || f == "0"
      session[:filter_customer] = "0"
      session[:filter_milestone] = "0"
      session[:filter_project] = "0"
    elsif f[0..0] == 'c'
      session[:filter_customer] = f[1..-1]
      session[:filter_milestone] = "0"
      session[:filter_project] = "0"
    elsif f[0..0] == 'p'
      session[:filter_customer] = "0"
      session[:filter_milestone] = "0"
      session[:filter_project] = f[1..-1]
    elsif f[0..0] == 'm'
      session[:filter_customer] = "0"
      session[:filter_milestone] = f[1..-1]
      session[:filter_project] = "0"
    elsif f[0..0] == 'u'
      session[:filter_customer] = "0"
      session[:filter_milestone] = "-1"
      session[:filter_project] = f[1..-1]
    end

    [:filter_user, :filter_hidden, :filter_status, :group_by, :hide_deferred, :hide_dependencies, :sort, :filter_type, :filter_severity, :filter_priority].each do |filter|
      session[filter] = params[filter]
    end

    session[:last_project_id] = session[:filter_project]
  end

############### This methods extracted to make Template Method design pattern #############################################3
  def create_entity
    return TaskRecord.new(:company => current_user.company)
  end

  def create_worklogs_for_tasks_create(files)
    # task created
    work_log = WorkLog.create_task_created!(@task, current_user)
    work_log.notify(files)

    work_log = WorkLog.build_work_added_or_comment(@task, current_user, params)
    work_log.save if work_log
  end

  def set_last_task(task)
    session[:last_task_id] = task.id if task.is_a?(TaskRecord)
  end
end
