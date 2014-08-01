module Boutique
  class App < Sinatra::Base
    set :raise_errors, false
    set :show_exceptions, false

    error do
      Pony.mail(
        :to => Boutique.config.dev_email,
        :subject => 'Boutique Error',
        :body => request.env['sinatra.error'].to_s
      ) if Boutique.config.dev_email
    end

    get '/subscribe/:list_key' do
      list = get_list(params[:list_key])
      begin
        subscriber = Subscriber.find_or_create(
          list_key: list.key,
          email: params[:email])
        Emailer.new(list).deliver_zero(subscriber) rescue nil
        jsonp
      rescue Sequel::ValidationFailed => e
        halt 400, e.message
      end
    end

    get '/confirm/:list_key/:id/:secret' do
      list = get_list(params[:list_key])
      subscriber = get_subscriber(params[:id], list, params[:secret])
      subscriber.confirm!(params[:secret])
      jsonp
    end

    get '/unsubscribe/:list_key/:id/:secret' do
      list = get_list(params[:list_key])
      subscriber = get_subscriber(params[:id], list, params[:secret])
      subscriber.unconfirm!(params[:secret])
      jsonp
    end

    private
    def jsonp
      params[:jsonp].nil? ? '' : "#{params[:jsonp]}()"
    end

    def get_list(list_key)
      List[list_key] || halt(404)
    end

    def get_subscriber(id, list, secret)
      Subscriber.first(
        id: params[:id],
        list_key: list.key,
        secret: secret) || halt(404)
    end
  end
end
