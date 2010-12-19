require 'i18n/backend/active_record'

module Interpret
  class Engine < Rails::Engine
    initializer "interpret.register_i18n_active_record_backend" do |app|
      I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Memoize)
      I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Flatten)

      Interpret.backend = I18n::Backend::ActiveRecord.new
      app.config.i18n.backend = Interpret.backend
    end
  end
end
