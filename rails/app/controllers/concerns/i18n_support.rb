module I18nSupport
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  # Allow to change the I18n locale by sendng a request like "example.com?locale=en"
  def set_locale
    # convert the GET parameter to a symbol as well
    locale = params[:locale].to_s.strip.to_sym

    # check if this locale is supported else use the default one.
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  end
end
