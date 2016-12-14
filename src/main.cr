# Alternative to the original Crystal main function, that will initialize and
# run Crystal in a specific Thread, so we can freely attach and detach native
# threads.
#
# This is required because JNI `Env` are only valid for a single fiber, and thus
# can't be shared between fibers. We also can't detach the main thread, because
# then we wouldn't be able to attach any thread anymore. The solution is to boot
# crystal inside a new thread, where we can freely attach a thread (actually
# fibers) to make some JNI calls and immediately detach again.
macro redefine_main(name = main)
  # :nodoc:
  fun main = {{name}}(argc : Int32, argv : UInt8**) : Int32
    thread = Thread.new do
      %ex = nil
      %status = begin
        GC.init
        {{yield LibCrystalMain.__crystal_main(argc, argv)}}
        0
      rescue ex
        %ex = ex
        1
      end

      AtExitHandlers.run %status
      %ex.inspect_with_backtrace STDERR if %ex
      STDOUT.flush
      STDERR.flush
      %status
    end

    {% if flag?(:android) %}
      0
    {% else%}
      thread.join.not_nil!
    {% end %}
  end
end

redefine_main do |main|
  {{main}}
end
