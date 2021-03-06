require 'logger'
require 'optparse'

module Bowler
  class CLI

    def self.start(args)
      options = {
        without: []
      }
      OptionParser.new {|opts|
        opts.banner = "Usage: bowl [options] <process>..."

        opts.on('-w', '--without <process>', 'Exclude a process from being launched') do |process|
          options[:without] << process.to_sym
        end

        opts.on_tail('-o', '--output-only', 'Output the apps to be started') do
          options[:output_only] = true
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        opts.on_tail('-v', '--version', 'Show the gem version') do
          puts "Bowler #{Bowler::VERSION}"
          exit
        end
      }.parse!(args)

      processes = args.map(&:to_sym)

      tree = Bowler::DependencyTree.load
      to_launch = tree.dependencies_for(processes) - options[:without]

      if options[:output_only]
        puts to_launch.join("\n")
      else
        logger.info "Starting #{to_launch.join(', ')}..."
        start_foreman_with( launch_string(to_launch) )
      end
    rescue PinfileNotFound
      logger.error "Bowler could not find a Pinfile in the current directory."
    rescue PinfileError => e
      logger.error "Bowler could not load the Pinfile due to an error: #{e}"
    end

    def self.logger
      @@logger ||= Logger.new(STDOUT)
    end

    def self.logger=(logger)
      @@logger = logger
    end

    def self.build_command(launch_string)
      "#{self.foreman_exec} start -c #{launch_string}"
    end

  private
    def self.launch_string(processes)
      processes.map {|process|
        "#{process}=1"
      }.sort.join(',')
    end

    def self.start_foreman_with(launch_string)
      exec ( self.build_command launch_string )
    end

    def self.foreman_exec
      ENV["BOWLER_FOREMAN_EXEC"] || "foreman"
    end

  end
end
