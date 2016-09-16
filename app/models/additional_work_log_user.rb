class AdditionalWorkLogUser < ActiveRecord::Base
  belongs_to :work_log
  belongs_to :user
  # attr_accessible :title, :body
end
