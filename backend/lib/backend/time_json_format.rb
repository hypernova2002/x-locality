# frozen_string_literal: true

# Ruby's Time#to_json defaults to Time#to_s ("2026-09-01 08:20:39 UTC") -
# not actually ISO 8601, and ambiguous for JSON clients to parse reliably.
# Every timestamp in this API is UTC (see config/providers/db.rb), so this
# makes that explicit and unambiguous in the wire format too.
class Time
  def to_json(*args)
    iso8601(3).to_json(*args)
  end
end

class DateTime
  def to_json(*args)
    to_time.iso8601(3).to_json(*args)
  end
end
