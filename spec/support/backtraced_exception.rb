# frozen_string_literal: true

class BacktracedException < StandardError
  attr_accessor :backtrace

  def initialize(opts)
    @backtrace = opts[:backtrace]
  end

  def set_backtrace(bt)
    @backtrace = bt
  end
end
