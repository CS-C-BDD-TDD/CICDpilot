# Helper class for Courses of Action
module CourseOfActionHelper
  include StixMarkingHelper

  def collect_suggested_coas(indicators)
    return [] unless indicators.present?

    suggested_coas = indicators.reject { |i|
      i.course_of_actions.blank? }.collect(&:course_of_actions).flatten

    suggested_coas
  end

  def collect_potential_coas(ets)
    return [] unless ets.present?

    potential_coas = ets.reject { |et|
      et.course_of_actions.blank? }.collect(&:course_of_actions).flatten

    potential_coas
  end
end
