module librangemap_integer
  implicit none
  private
  public :: map_integer_value

contains
  function map_integer_value(value, input_min, input_max, output_min, output_max, clip) result(mapped)
    integer, intent(in) :: value
    integer, intent(in) :: input_min
    integer, intent(in) :: input_max
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip

    logical :: do_clip
    integer :: bounded_value
    integer :: input_span
    real(8) :: output_span
    real(8) :: mapped

    if (input_min >= input_max) stop 1
    if (output_min >= output_max) stop 2

    do_clip = .false.
    if (present(clip)) do_clip = clip

    bounded_value = value
    if (do_clip) then
      if (bounded_value < input_min) bounded_value = input_min
      if (bounded_value > input_max) bounded_value = input_max
    else
      if (bounded_value < input_min .or. bounded_value > input_max) stop 3
    end if

    input_span = input_max - input_min
    output_span = output_max - output_min
    mapped = output_min + (real(bounded_value - input_min, kind=8) / real(input_span, kind=8)) * output_span
  end function
end module
