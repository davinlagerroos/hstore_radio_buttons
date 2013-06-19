require "hstore_radio_buttons/version"
require "hstore_radio_buttons/configuration"
require 'active_support/concern'
require 'active_support/dependencies/autoload'

module HstoreRadioButtons
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload

  autoload :HstoreRadioData

  module ClassMethods
    def hstore_radio_buttons
    end
  end

  def hstore_data_proxy
    if self.hstore_radio_data.nil?
      self.build_hstore_radio_data.hstore_data
    else
      self.hstore_radio_data.hstore_data
    end
  end
  private :hstore_data_proxy

  included do
    has_one :hstore_radio_data, :class_name => 'HstoreRadioButtons::HstoreRadioData', :as => :model
    HstoreRadioButtons::Configuration.from_yaml(self)
  end
end
