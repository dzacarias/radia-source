module DashboardHelper
  
  def current_broadcast
    b = ProgramSchedule.active_instance.now_playing
    if b.gap?
      b.name
    else
      link_to b.name, program_broadcast_path(b.program, b)
    end
  end
  
  def recently_delivered_singles
    Single.find_recently_delivered(10) + Spot.find_recently_delivered(10)
  end
  
  def upcoming_broadcasts
    ProgramSchedule.active_instance.broadcasts_and_gaps(Time.now, 5.hours.from_now)
  end
  
end
