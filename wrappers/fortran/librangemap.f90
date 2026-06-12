module librangemap_integer
  implicit none
  private
  public :: map_integer_value, map_float_value, map_boolean_value, map_temporal_value, map_categorical_value, map_bytes_value, map_text_value
  public :: map_integer_sequence_value, map_integer_nested_sequence_value, map_image_value
  public :: map_object_value, map_object_field_t

  integer, parameter :: MAP_FAMILY_INTEGER = 1
  integer, parameter :: MAP_FAMILY_FLOAT = 2
  integer, parameter :: MAP_FAMILY_BOOLEAN = 3
  integer, parameter :: MAP_FAMILY_TEXT = 4
  integer, parameter :: MAP_FAMILY_CATEGORICAL = 5
  integer, parameter :: MAP_FAMILY_OBJECT = 6

  type :: map_object_field_t
    character(len=:), allocatable :: name
    integer :: family = 0
    integer :: int_value = 0
    real(8) :: float_value = 0.0d0
    logical :: bool_value = .false.
    character(len=:), allocatable :: text_value
    integer, allocatable :: int_sequence(:)
    type(map_object_field_t), allocatable :: object_fields(:)
    character(len=:), allocatable :: text_mode
    character(len=:), allocatable :: text_alphabet
    character(len=:), allocatable :: categorical_vocab(:)
    integer :: int_input_min = 0
    integer :: int_input_max = 0
    real(8) :: float_input_min = 0.0d0
    real(8) :: float_input_max = 1.0d0
    real(8) :: output_min = -1.0d0
    real(8) :: output_max = 1.0d0
    logical :: clip = .false.
    logical :: allow_empty = .false.
    logical :: allow_unknown = .false.
    logical :: allow_missing = .false.
    real(8) :: false_value = -1.0d0
    real(8) :: true_value = 1.0d0
  end type

  interface map_image_value
    module procedure map_image_value_bytes
    module procedure map_image_value_matrix
  end interface

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

  function map_float_value(value, input_min, input_max, output_min, output_max, clip) result(mapped)
    real(8), intent(in) :: value
    real(8), intent(in) :: input_min
    real(8), intent(in) :: input_max
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip
    logical :: do_clip
    real(8) :: bounded_value
    real(8) :: input_span
    real(8) :: output_span
    real(8) :: mapped

    if (value /= value .or. input_min /= input_min .or. input_max /= input_max .or. output_min /= output_min .or. output_max /= output_max) stop 4
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
    mapped = output_min + ((bounded_value - input_min) / input_span) * output_span
  end function

  function map_boolean_value(value, output_min, output_max, false_value, true_value) result(mapped)
    logical, intent(in) :: value
    real(8), intent(in), optional :: output_min
    real(8), intent(in), optional :: output_max
    real(8), intent(in), optional :: false_value
    real(8), intent(in), optional :: true_value
    real(8) :: local_output_min
    real(8) :: local_output_max
    real(8) :: local_false_value
    real(8) :: local_true_value
    real(8) :: mapped

    local_output_min = -1.0d0
    local_output_max = 1.0d0
    if (present(output_min)) local_output_min = output_min
    if (present(output_max)) local_output_max = output_max
    if (local_output_min /= local_output_min .or. local_output_max /= local_output_max) stop 4
    if (local_output_min >= local_output_max) stop 2

    local_false_value = local_output_min
    local_true_value = local_output_max
    if (present(false_value)) local_false_value = false_value
    if (present(true_value)) local_true_value = true_value
    if (local_false_value /= local_false_value .or. local_true_value /= local_true_value) stop 4
    if (local_false_value < local_output_min .or. local_false_value > local_output_max .or. local_true_value < local_output_min .or. local_true_value > local_output_max) stop 2
    if (local_false_value == local_true_value) stop 2

    if (value) then
      mapped = local_true_value
    else
      mapped = local_false_value
    end if
  end function

  function map_temporal_value(value, input_min, input_max, output_min, output_max, clip) result(mapped)
    real(8), intent(in) :: value
    real(8), intent(in) :: input_min
    real(8), intent(in) :: input_max
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip
    logical :: do_clip
    real(8) :: bounded_value
    real(8) :: input_span
    real(8) :: output_span
    real(8) :: mapped

    if (value /= value .or. input_min /= input_min .or. input_max /= input_max .or. output_min /= output_min .or. output_max /= output_max) stop 4
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
    mapped = output_min + ((bounded_value - input_min) / input_span) * output_span
  end function

  function map_categorical_value(value, vocabulary, output_min, output_max) result(mapped)
    character(len=*), intent(in) :: value
    character(len=*), intent(in) :: vocabulary(:)
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    integer :: i
    integer :: j
    integer :: index
    real(8) :: output_span
    logical :: duplicate
    real(8) :: mapped

    if (output_min /= output_min .or. output_max /= output_max) stop 4
    if (output_min >= output_max) stop 2
    if (size(vocabulary) <= 0) stop 5
    if (len_trim(value) <= 0) stop 5

    index = -1
    do i = 1, size(vocabulary)
      if (len_trim(vocabulary(i)) <= 0) stop 5
      duplicate = .false.
      do j = 1, i - 1
        if (trim(vocabulary(j)) == trim(vocabulary(i))) then
          duplicate = .true.
          exit
        end if
      end do
      if (duplicate) stop 5
      if (trim(vocabulary(i)) == trim(value)) index = i
    end do

    if (index < 0) stop 6

    if (size(vocabulary) == 1) then
      mapped = (output_min + output_max) / 2.0d0
      return
    end if

    output_span = output_max - output_min
    mapped = output_min + (real(index - 1, kind=8) / real(size(vocabulary) - 1, kind=8)) * output_span
  end function

  function map_bytes_value(value, output_min, output_max, clip, allow_empty) result(mapped)
    character(len=*), intent(in) :: value
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip
    logical, intent(in), optional :: allow_empty
    logical :: do_clip
    logical :: do_allow_empty
    integer :: i
    integer :: byte_value
    integer :: value_length
    real(8), allocatable :: mapped(:)

    if (output_min /= output_min .or. output_max /= output_max) stop 4
    if (output_min >= output_max) stop 2

    do_clip = .false.
    if (present(clip)) do_clip = clip
    do_allow_empty = .false.
    if (present(allow_empty)) do_allow_empty = allow_empty

    value_length = len_trim(value)
    if (value_length <= 0) then
      if (do_allow_empty) then
        allocate(mapped(0))
        return
      end if
      stop 5
    end if

    allocate(mapped(value_length))
    do i = 1, value_length
      byte_value = ichar(value(i:i))
      if (.not. do_clip .and. (byte_value < 0 .or. byte_value > 255)) stop 6
      if (do_clip) then
        if (byte_value < 0) byte_value = 0
        if (byte_value > 255) byte_value = 255
      end if
      mapped(i) = output_min + (real(byte_value, kind=8) / 255.0d0) * (output_max - output_min)
    end do
  end function

  function map_text_value(value, output_min, output_max, mode, alphabet, clip, allow_empty) result(mapped)
    character(len=*), intent(in) :: value
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    character(len=*), intent(in), optional :: mode
    character(len=*), intent(in), optional :: alphabet
    logical, intent(in), optional :: clip
    logical, intent(in), optional :: allow_empty
    character(len=:), allocatable :: local_mode
    character(len=:), allocatable :: local_alphabet
    logical :: do_clip
    logical :: do_allow_empty
    integer :: i
    integer :: j
    integer :: index
    integer :: codepoint
    integer :: alphabet_length
    real(8) :: output_span
    real(8), allocatable :: mapped(:)

    if (output_min /= output_min .or. output_max /= output_max) stop 4
    if (output_min >= output_max) stop 2

    local_mode = 'codepoint'
    if (present(mode)) local_mode = trim(mode)
    local_alphabet = ''
    if (present(alphabet)) local_alphabet = alphabet
    do_clip = .false.
    if (present(clip)) do_clip = clip
    do_allow_empty = .false.
    if (present(allow_empty)) do_allow_empty = allow_empty

    if (len_trim(value) <= 0) then
      if (do_allow_empty) then
        allocate(mapped(0))
        return
      end if
      stop 5
    end if

    if (trim(local_mode) == 'codepoint') then
      allocate(mapped(len_trim(value)))
      output_span = output_max - output_min
      do i = 1, len_trim(value)
        codepoint = ichar(value(i:i))
        if (.not. do_clip .and. (codepoint < 0 .or. codepoint > 65535)) stop 6
        if (do_clip) then
          if (codepoint < 0) codepoint = 0
          if (codepoint > 65535) codepoint = 65535
        end if
        mapped(i) = output_min + (real(codepoint, kind=8) / 65535.0d0) * output_span
      end do
      return
    end if

    if (trim(local_mode) == 'alphabet') then
      alphabet_length = len_trim(local_alphabet)
      if (alphabet_length < 2) stop 5
      do i = 1, alphabet_length
        do j = i + 1, alphabet_length
          if (local_alphabet(i:i) == local_alphabet(j:j)) stop 5
        end do
      end do
      allocate(mapped(len_trim(value)))
      output_span = output_max - output_min
      do i = 1, len_trim(value)
        index = 0
        do j = 1, alphabet_length
          if (value(i:i) == local_alphabet(j:j)) then
            index = j
            exit
          end if
        end do
        if (index <= 0) stop 6
        if (alphabet_length == 1) then
          mapped(i) = (output_min + output_max) / 2.0d0
        else
          mapped(i) = output_min + (real(index - 1, kind=8) / real(alphabet_length - 1, kind=8)) * output_span
        end if
      end do
      return
    end if

    stop 6
  end function

  function map_integer_sequence_value(values, input_min, input_max, output_min, output_max, clip) result(mapped)
    integer, intent(in) :: values(:)
    integer, intent(in) :: input_min
    integer, intent(in) :: input_max
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip
    integer :: i
    real(8), allocatable :: mapped(:)

    if (size(values) <= 0) stop 5

    allocate(mapped(size(values)))
    do i = 1, size(values)
      mapped(i) = map_integer_value(values(i), input_min, input_max, output_min, output_max, clip)
    end do
  end function

  function map_integer_nested_sequence_value(values, input_min, input_max, output_min, output_max, clip) result(mapped)
    integer, intent(in) :: values(:,:)
    integer, intent(in) :: input_min
    integer, intent(in) :: input_max
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip
    integer :: i
    real(8), allocatable :: mapped(:,:)

    if (size(values, 1) <= 0 .or. size(values, 2) <= 0) stop 5

    allocate(mapped(size(values, 1), size(values, 2)))
    do i = 1, size(values, 1)
      mapped(i, :) = map_integer_sequence_value(values(i, :), input_min, input_max, output_min, output_max, clip)
    end do
  end function

  function map_image_value_bytes(value, output_min, output_max, clip, allow_empty) result(mapped)
    character(len=*), intent(in) :: value
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip
    logical, intent(in), optional :: allow_empty
    real(8), allocatable :: mapped(:)

    mapped = map_bytes_value(value, output_min, output_max, clip, allow_empty)
  end function

  function map_image_value_matrix(values, output_min, output_max, clip) result(mapped)
    integer, intent(in) :: values(:,:)
    real(8), intent(in) :: output_min
    real(8), intent(in) :: output_max
    logical, intent(in), optional :: clip
    integer :: i
    real(8), allocatable :: mapped(:,:)

    if (size(values, 1) <= 0 .or. size(values, 2) <= 0) stop 5

    allocate(mapped(size(values, 1), size(values, 2)))
    do i = 1, size(values, 1)
      mapped(i, :) = map_integer_sequence_value(values(i, :), 0, 255, output_min, output_max, clip)
    end do
  end function

  subroutine self_check()
    type(map_object_field_t), allocatable :: object_values(:)
    type(map_object_field_t), allocatable :: object_schema(:)

    if (abs(map_integer_value(50, 0, 100, -1.0d0, 1.0d0, .false.)) > 1e-12) stop 7
    if (abs(map_float_value(0.5d0, 0.0d0, 1.0d0, -1.0d0, 1.0d0, .false.)) > 1e-12) stop 7
    if (abs(map_boolean_value(.true., -1.0d0, 1.0d0, -1.0d0, 1.0d0) - 1.0d0) > 1e-12) stop 7
    if (size(map_text_value('cab', -1.0d0, 1.0d0, 'alphabet', 'abc', .false., .false.)) /= 3) stop 7
    if (size(map_bytes_value('ABC', -1.0d0, 1.0d0, .false., .false.)) /= 3) stop 7
    if (abs(map_categorical_value('cat', [character(len=3) :: 'cat', 'dog'], -1.0d0, 1.0d0) + 1.0d0) > 1e-12) stop 7
    if (abs(map_temporal_value(0.0d0, -10.0d0, 10.0d0, -1.0d0, 1.0d0, .false.)) > 1e-12) stop 7
    if (size(map_integer_sequence_value([0, 50, 100], 0, 100, -1.0d0, 1.0d0, .false.)) /= 3) stop 7
    if (size(map_integer_nested_sequence_value(reshape([0, 50, 100, 100], [2, 2]), 0, 100, -1.0d0, 1.0d0, .false.), 1) /= 2) stop 7
    if (size(map_image_value('ABC', -1.0d0, 1.0d0, .false., .false.)) /= 3) stop 7
    if (size(map_image_value(reshape([0, 127, 255, 64], [2, 2]), -1.0d0, 1.0d0, .false.), 1) /= 2) stop 7
    allocate(object_values(1))
    allocate(object_schema(1))
    object_schema(1)%name = 'age'
    object_schema(1)%family = MAP_FAMILY_INTEGER
    object_schema(1)%int_input_min = 0
    object_schema(1)%int_input_max = 100
    object_schema(1)%output_min = -1.0d0
    object_schema(1)%output_max = 1.0d0
    object_values(1)%name = 'age'
    object_values(1)%family = MAP_FAMILY_INTEGER
    object_values(1)%int_value = 25
    if (abs(map_object_value(object_values, object_schema)(1) - (-0.5d0)) > 1.0d-12) stop 7
  end subroutine

  function map_object_value(values, schema, allow_unknown, allow_empty, allow_missing) result(mapped)
    type(map_object_field_t), intent(in) :: values(:)
    type(map_object_field_t), intent(in) :: schema(:)
    logical, intent(in), optional :: allow_unknown
    logical, intent(in), optional :: allow_empty
    logical, intent(in), optional :: allow_missing
    logical :: do_allow_unknown
    logical :: do_allow_empty
    logical :: do_allow_missing
    integer :: i
    integer :: j
    integer :: value_index
    integer :: match_count
    type(map_object_field_t), allocatable :: sorted_schema(:)
    real(8), allocatable :: mapped(:)

    do_allow_unknown = .false.
    if (present(allow_unknown)) do_allow_unknown = allow_unknown
    do_allow_empty = .false.
    if (present(allow_empty)) do_allow_empty = allow_empty
    do_allow_missing = .false.
    if (present(allow_missing)) do_allow_missing = allow_missing

    if (size(schema) <= 0) then
      if (do_allow_empty) then
        allocate(mapped(0))
        return
      end if
      stop 5
    end if

    if (size(values) <= 0) stop 5
    if (count_empty_object_names(values) > 0) stop 5
    if (count_empty_object_names(schema) > 0) stop 5

    if (count_duplicate_object_fields(values) > 0) stop 6
    if (count_duplicate_object_fields(schema) > 0) stop 6

    allocate(sorted_schema(size(schema)))
    sorted_schema = schema
    call sort_object_fields_by_name(sorted_schema)
    allocate(mapped(size(sorted_schema)))
    mapped = 0.0d0

    do i = 1, size(sorted_schema)
      if (sorted_schema(i)%family < MAP_FAMILY_INTEGER .or. sorted_schema(i)%family > MAP_FAMILY_OBJECT) stop 5
      value_index = 0
      match_count = 0
      do j = 1, size(values)
        if (trim(values(j)%name) == trim(sorted_schema(i)%name)) then
          value_index = j
          match_count = match_count + 1
        end if
      end do
      if (value_index <= 0) then
        if (.not. do_allow_missing .and. .not. sorted_schema(i)%allow_missing) stop 7
        mapped(i) = (sorted_schema(i)%output_min + sorted_schema(i)%output_max) / 2.0d0
      else
        if (match_count > 1) stop 6
        mapped(i) = map_object_member_value(values(value_index), sorted_schema(i), do_allow_empty, sorted_schema(i)%allow_unknown)
      end if
    end do

    if (.not. do_allow_unknown) then
      do i = 1, size(values)
        value_index = 0
        do j = 1, size(sorted_schema)
          if (trim(values(i)%name) == trim(sorted_schema(j)%name)) value_index = value_index + 1
        end do
        if (value_index == 0) stop 8
      end do
    end if
  end function

  function map_object_member_value(value, schema, allow_empty, allow_unknown) result(mapped)
    type(map_object_field_t), intent(in) :: value
    type(map_object_field_t), intent(in) :: schema
    logical, intent(in), optional :: allow_empty
    logical, intent(in), optional :: allow_unknown
    logical :: do_allow_empty
    logical :: do_allow_unknown
    real(8), allocatable :: nested(:)
    real(8) :: mapped
    integer :: i
    real(8) :: span

    do_allow_empty = .false.
    if (present(allow_empty)) do_allow_empty = allow_empty
    do_allow_unknown = .false.
    if (present(allow_unknown)) do_allow_unknown = allow_unknown

    if (value%family /= schema%family) stop 9
    if (schema%family == MAP_FAMILY_INTEGER) then
      if (schema%int_input_min >= schema%int_input_max) stop 1
      mapped = map_integer_value(value%int_value, schema%int_input_min, schema%int_input_max, schema%output_min, schema%output_max, schema%clip)
      return
    end if

    if (schema%family == MAP_FAMILY_FLOAT) then
      if (schema%float_input_min >= schema%float_input_max) stop 1
      mapped = map_float_value(value%float_value, schema%float_input_min, schema%float_input_max, schema%output_min, schema%output_max, schema%clip)
      return
    end if

    if (schema%family == MAP_FAMILY_BOOLEAN) then
      mapped = map_boolean_value(value%bool_value, schema%output_min, schema%output_max, schema%false_value, schema%true_value)
      return
    end if

    if (schema%family == MAP_FAMILY_TEXT) then
      if (.not. allocated(value%text_value)) stop 5
      mapped = map_text_value(value%text_value, schema%output_min, schema%output_max, schema%text_mode, schema%text_alphabet, schema%clip, do_allow_empty)
      return
    end if

    if (schema%family == MAP_FAMILY_CATEGORICAL) then
      if (.not. allocated(value%text_value)) stop 5
      if (.not. allocated(schema%categorical_vocab)) stop 5
      mapped = map_categorical_value(trim(value%text_value), schema%categorical_vocab, schema%output_min, schema%output_max)
      return
    end if

    if (schema%family == MAP_FAMILY_OBJECT) then
      if (.not. allocated(value%object_fields) .or. .not. allocated(schema%object_fields)) stop 5
      nested = map_object_value(value%object_fields, schema%object_fields, do_allow_unknown, do_allow_empty, schema%allow_missing)
      if (size(nested) == 0) then
        if (schema%allow_empty) then
          mapped = (schema%output_min + schema%output_max) / 2.0d0
        else
          stop 5
        end if
      else
        mapped = 0.0d0
        do i = 1, size(nested)
          mapped = mapped + nested(i)
        end do
        span = real(size(nested), kind=8)
        if (span > 0.0d0) mapped = mapped / span
      end if
      if (mapped < schema%output_min .or. mapped > schema%output_max) stop 2
      deallocate(nested)
      return
    end if

    stop 11
  end function

  function count_duplicate_object_fields(values) result(found)
    type(map_object_field_t), intent(in) :: values(:)
    integer :: i
    integer :: j
    integer :: found
    found = 0
    do i = 1, size(values)
      do j = i + 1, size(values)
        if (trim(values(i)%name) == trim(values(j)%name)) found = found + 1
      end do
    end do
  end function

  function count_empty_object_names(values) result(found)
    type(map_object_field_t), intent(in) :: values(:)
    integer :: i
    integer :: found
    found = 0
    do i = 1, size(values)
      if (len_trim(values(i)%name) <= 0) found = found + 1
    end do
  end function

  subroutine sort_object_fields_by_name(fields)
    type(map_object_field_t), intent(inout) :: fields(:)
    integer :: i
    integer :: j
    type(map_object_field_t) :: current_field

    do i = 2, size(fields)
      current_field = fields(i)
      j = i - 1
      do while (j >= 1 .and. trim(fields(j)%name) > trim(current_field%name))
        fields(j + 1) = fields(j)
        j = j - 1
      end do
      fields(j + 1) = current_field
    end do
  end subroutine

end module
