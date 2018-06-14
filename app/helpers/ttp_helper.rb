# Helper class for TTP
module TtpHelper
  include StixMarkingHelper

  def collect_related_ets(ttps)
    return [] unless ttps.present?

    related_ets = ttps.reject { |t|
      t.exploit_targets.blank? }.collect(&:exploit_targets).flatten

    related_ets
  end

  def collect_indicated_ttps(indicators)
    return [] unless indicators.present?

    indicated_ttps = indicators.reject { |i|
      i.ttps.blank? }.collect(&:ttps).flatten

    indicated_ttps
  end
end
