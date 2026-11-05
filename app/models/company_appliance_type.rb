class CompanyApplianceType < ApplicationRecord
  belongs_to :company
  belongs_to :appliance_type

  validates :appliance_type_id, uniqueness: { scope: :company_id }
end
