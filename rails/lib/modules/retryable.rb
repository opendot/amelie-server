module Retryable
  # Allow to retry a block
  # Used in Synchronization for the http requests

  def retry_with(opts = {}, &blk)
    fail("Block is required") if blk.nil?

    attempts    = opts[:attempts] || 5
    delay       = opts[:delay] || 1
    delay_inc   = opts[:increment_delay] == true
    delay_sleep = opts[:sleep] == true
    debug       = opts[:debug] == true

    last_err = nil

    1.upto(attempts) do |i|
      begin
        logger.debug "Trying #{i} attempt..." if debug
        blk.call
        logger.debug "Success attempt #{i}" if debug
        return
      rescue Exception => err
        last_err = err
        logger.debug "Got an error on #{i} attemp: #{err}" if debug
        delay += i if delay_inc
        sleep(delay) if delay_sleep
      end
    end

    logger.debug "Retry attempts are exhausted (#{attempts} total)" if debug
    raise last_err
  end

end