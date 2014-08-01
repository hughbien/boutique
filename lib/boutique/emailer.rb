module Boutique
  class Emailer
    def initialize(list, directory = nil)
      @list = list
      @directory = directory
    end

    def render(path, locals = {}, pre = false)
      path = @directory ?
        File.join(@directory, path) :
        full_path(path)
      raise "File not found: #{path}" if !File.exist?(path)

      yaml, body = preamble(path)
      templates_for(path).each do |template|
        blk = proc { body }
        body = template.new(path, &blk).render(self, locals)
      end

      pre ? [yaml, body] : body
    end

    def deliver(subscriber, path, locals = {})
      locals = locals.merge(
        subscribe_url: @list.subscribe_url,
        confirm_url: subscriber.confirm_url,
        unsubscribe_url: subscriber.unsubscribe_url)
      yaml, body = self.render(path, locals, true)
      if yaml['day'] == 0
        ymd = Date.today.strftime("%Y-%m-%d")
        Email.create(email_key: "#{yaml['key']}-#{ymd}", subscriber: subscriber)
      else
        raise "Unconfirmed #{subscriber.email} for #{yaml['key']}" if !subscriber.confirmed?
        Email.create(email_key: yaml['key'], subscriber: subscriber)
      end
      Pony.mail(
        to: subscriber.email,
        from: @list.from,
        subject: yaml['subject'],
        headers: {'Content-Type' => 'text/html'},
        body: body)
    rescue DataMapper::SaveFailureError
      raise "Duplicate email #{yaml['key']} to #{subscriber.email}"
    end

    def deliver_zero(subscriber)
      self.deliver(subscriber, emails[0])
    end

    def blast(path, locals = {})
      yaml, body = preamble(full_path(path))
      email_key = yaml['key']
      @list.subscribers.all(confirmed: true).each do |subscriber|
        # TODO: speed up by moving filter outside of loop
        if Email.first(email_key: yaml['key'], subscriber: subscriber).nil?
          self.deliver(subscriber, path, locals)
        end
      end
    end

    def drip
      today = Date.today
      max_day = emails.keys.max || 0
      subscribers = @list.subscribers.all(
        :confirmed => true,
        :drip_on.lt => today,
        :drip_day.lt => max_day)
      subscribers.each do |subscriber|
        subscriber.drip_on = today
        subscriber.drip_day += 1
        subscriber.save
        if (email_path = emails[subscriber.drip_day])
          self.deliver(subscriber, email_path)
        end
      end
    end

    private
    def full_path(path)
      File.join(@list.emails, path)
    end

    def templates_for(path)
      basename = File.basename(path)
      basename.split('.')[1..-1].reverse.map { |ext| Tilt[ext] }
    end

    def emails
      @emails ||= begin
        emails = {}
        Dir.entries(@list.emails).each do |filename|
          next if File.directory?(filename)
          # TODO: stop duplicating calls to preamble, store in memory
          yaml, body = preamble(full_path(filename))
          if yaml && yaml['day'] && yaml['key']
            emails[yaml['day']] = filename
          end
        end
        emails
      end
    end

    def preamble(path)
      data = Preamble.load(path)
      [data.metadata, data.content]
    rescue
      [{}, File.read(path)]
    end
  end
end
