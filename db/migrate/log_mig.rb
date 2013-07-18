f = File.new("migrations_problematicas.txt", "r")
o = File.new("log_problematicas.csv", "w")
fc = f.read.split("\n")
fc.each do |arq|
  cmd = "git log --pretty=format:\"%H;%ad\" --date=local  #{arq}"
  stat = IO.popen(cmd).read.split("\n")
  stat.each do |l|
    el = l.split(";")
    o.write("#{arq};#{el[0]}\n")
  end
end
f.close
o.close