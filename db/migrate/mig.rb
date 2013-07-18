exclude = []
exclude << "20081121133029_cache_project_task_counts.rb"
exclude << "20081121140153_cache_project_milestone_counts.rb"
exclude << "20081123091936_add_filter_by_severity_priority.rb"
exclude << "20090103140701_hide_dependencies_and_deferred_fixup.rb"
months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

fl = `ls`.split "\n"
fl.each do |fn|
  unless exclude.member?(fn) then
    fn =~ /^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{6})_(.*)/
    r = Regexp.last_match
    unless r == nil
      info = [fn]
      cmd = "git log #{fn}"
      stat = IO.popen(cmd).read.split("\n")
      stat.each do |line|
        line =~ /commit ([0-9a-f]+)/
        info << Regexp.last_match[1] unless Regexp.last_match == nil
        line =~ /Date\:\s+\w+\s(\w+)\s(\d{1,2})\s(\d{2})\:(\d{2})\:(\d{2})\s(\d{4})\s([\+\-]\d{2})(\d{2})/
        unless Regexp.last_match == nil
          r = Regexp.last_match
          if r.length == 9
            month = months.index r[1]
            utc_offset = "#{r[7]}:#{r[8]}"
            info << Time.new(r[6].to_i, month, r[2].to_i, r[3].to_i, r[4].to_i, r[5].to_i, utc_offset)
            info << utc_offset
          else
            info << line
          end
          puts info.join(';')
          info = [fn]
        end
      end
    end
  end
end