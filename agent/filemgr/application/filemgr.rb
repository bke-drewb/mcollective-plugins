class MCollective::Application::Filemgr<MCollective::Application

  description "Generic File Manager Client"
  usage "Usage: mc-filemgr [--file FILE] [touch|remove|status]"
  usage "Usage: mc-filemgr [--dir DIR] list"
  
  option :file,
         :description    => "File to manage",
         :arguments      => ["--file FILE", "-f FILE"]

  option :details,
         :description    => "Show full file details",
         :arguments      => ["--details", "-d"],
         :type           => :bool

  option :directory,
         :description    => "Directory to list",
         :arguments      => "--dir DIR"

  def post_option_parser(configuration)
    configuration[:command] = ARGV.shift if ARGV.size > 0
  end

  def validate_configuration(configuration)
    # Validate dir/file based on action
    configuration[:command] = "touch" unless configuration.include?(:command)
  end

  def main
    mc = rpcclient("filemgr", :options => options)

    case configuration[:command]
    when "remove"
      printrpc mc.remove(:file => configuration[:file])

    when "touch"
      printrpc mc.touch(:file => configuration[:file])

    when "status"
      if configuration[:details]
        printrpc mc.status(:file => configuration[:file])
      else
        mc.status(:file => configuration[:file]).each do |resp|
          printf("%-40s: %s\n", resp[:sender], resp[:data][:output] || resp[:statusmsg] )
        end
      end

    when "list"
      if configuration[:details]
        mc.list(:dir => configuration[:directory]).each do |resp|
          printf("%-40s: %s\n", resp[:sender], resp[:data][:statusmsg])
          files = resp[:data][:directory].sort_by { |key, val| key }
          files.each do |key,val|
            printf("%5s%-12s\t%-12s\t%s\t%s\t%s\n", "", val[:uid_name], val[:gid_name], val[:size], val[:mtime], key)
          end
        end
      else
        mc.list(:dir => configuration[:directory]).each do |resp|
          printf("%-40s: %s\n", resp[:sender], resp[:data][:statusmsg])
          files = resp[:data].keys.sort
          files.each do |key,val|
            printf("%5s%s\n", "", key)
          end
        end
      end

    else
      mc.disconnect
      puts "Valid commands are 'touch', 'remove', 'status' and 'list'"
      exit 1
    end

    mc.disconnect
    printrpcstats
  end
end
