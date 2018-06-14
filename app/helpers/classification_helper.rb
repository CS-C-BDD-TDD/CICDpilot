# Helper class for classification and portion marking features
module ClassificationHelper

  def classification(portion_marking)
		case portion_marking
			when 'U' then 'Unclassified'
			when 'C' then 'Confidential'
			when 'S' then 'Secret'
			when 'TS' then 'Top Secret'
			else ''
		end
  end

	def addPortionMarkingToCSV(headers=nil, row=nil, cybox_object=nil)
    unless defined?(Setting.CLASSIFICATION) && Setting.CLASSIFICATION
      return headers unless headers.nil?
      return row unless row.nil?
      return nil
    end
    if headers.present?
      headers.unshift('Classification')
      headers
    elsif row.present?
      if cybox_object.present? && cybox_object.portion_marking.present?
        row.unshift("(#{cybox_object.portion_marking})")
      elsif cybox_object.respond_to?(:combined_score) &&
          cybox_object.combined_score.present?
        row.unshift('(U)')
      else
        row.unshift('(TS)')
      end
      row
    else
      nil
    end
  end
end