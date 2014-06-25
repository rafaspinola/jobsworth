class Newsletter

	def self.send_notifications
		users = get_users_to_notify
		users.each do |id, u|
			body = build_email_html_body(u)
			subject = build_subject(u)
			NewsletterMailer.newsletter_email(u, subject, body)
		end
	end

	protected

	def self.build_subject(u)
	  	today = Date.today.strftime("%d/%m")
	  	count_overdue = u[:tasks_overdue].count
	  	count_today = u[:tasks_today].count
	  	count_tomorrow = u[:tasks_tomorrow].count
	  	"Tarefas #{today}: #{count_overdue} atrasadas, #{count_today} hoje, #{count_tomorrow} amanha"
	end

	def self.build_title(ptag, style, text)
		"#{ptag}#{style}#{text}</span></p>"
	end

	def self.build_task_item(t, overdue=false)
		text = "<li>#{t[:num]} - #{t[:name]}"
		if overdue then
			formatted_date = t[:due_at].strftime("%d/%m/%Y")
			text += " - Vencida em #{formatted_date}"
		end
		text += "</li>"
		text
	end

	def self.build_task_list(ptag, style, text, tasks, overdue=false)
		text = build_title(ptag, style, text)
		text += "<ul>"
		tasks.each do |t|
			text += build_task_item(t, overdue)
		end
		text += "</ul>"
		text
	end

	def self.build_email_html_body(u)
		ptag = "<p style=\"margin-bottom: 10px; font-family: Arial, Helvetica, sans-serif; font-size: 1.2em;\">"
		tstyle = "<span style=\"font-weight: bold; font-size: 1.4em;\">"
		toverduestyle = "<span style=\"color:#FF0000; font-weight: bold; font-size: 1.4em;\">"
		text = "#{ptag}#{u[:name]},</p>"
		text += build_task_list(ptag, toverduestyle, "Tarefas atrasadas", u[:tasks_overdue], true)
		text += build_task_list(ptag, tstyle, "Tarefas de hoje", u[:tasks_today])
		text += build_task_list(ptag, tstyle, "Tarefas de amanh&atilde;", u[:tasks_tomorrow])
		text
	end

	def self.get_users_to_notify
		tsks = TaskRecord.includes(:users).where("due_at <= ? AND completed_at IS NOT NULL", Date.tomorrow)
		users_to_notify = {}
		tsks.each do |t|
			t.users.each do |u|
				if u.active then
					users_to_notify[u.id] = build_user(u) if users_to_notify[u.id] == nil
					task_element = build_task(t)
					users_to_notify[u.id][:tasks_overdue].append(task_element) if t.due_at < Date.today
					users_to_notify[u.id][:tasks_today].append(task_element) if t.due_at == Date.today
					users_to_notify[u.id][:tasks_tomorrow].append(task_element) if t.due_at == Date.tomorrow
				end
			end
		end
		users_to_notify
	end

	def self.build_user(u)
		{
			:name => u.name,
			:email => u.email,
			:tasks_overdue => [],
			:tasks_today => [],
			:tasks_tomorrow => []
		}
	end

	def self.build_task(t)
		{ :num => t.task_num, :name => t.name, :due_at => t.due_at }
	end
end