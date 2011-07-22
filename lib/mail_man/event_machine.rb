module MailMan
  module EventMachine
    def self.start!
      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          EM.stop if (forked && EM.reactor_running?)        
          Thread.new { EM.run }
          die_gracefully_on_signal
        end
      end
    end

    def self.die_gracefully_on_signal
      Signal.trap("INT")  { EM.stop }
      Signal.trap("TERM") { EM.stop }
    end
  end
end

MailMan::EventMachine.start!
