class Experience < ActiveRecord::Base
  KINDS = %w(education work extracurricular).freeze

  belongs_to :resume, inverse_of: :experiences

  include NullableDateTime
  nullable_datetime :end_date, :no_end_date, true

  validates_presence_of :organization, :location, :title, :start_date

  auto_strip_attributes :organization, :location, :title, :description, squish: false

  default_scope lambda { order("COALESCE(end_date, '#{Date.tomorrow.to_formatted_s(:db)}') DESC") }

  def duration
    start = I18n.l(start_date, format: :duration)
    if end_date
      I18n.t('values.duration.ended_html', start: start,
        :end => I18n.l(end_date, format: :duration), months: duration_in_months)
    else
      I18n.t('values.duration.ongoing_html', start: start)
    end.html_safe
  end

  def duration_in_months
    (end_date.year*12+end_date.month) - (start_date.year*12+start_date.month) + 1
  end

  def to_s
    title
  end
end
