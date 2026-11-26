# frozen_string_literal: true

require_relative("test_helper")

# Checks the operating systems a runner can have.
class OSTest < Minitest::Test
  # Glossary, "OS": "A runner's operating system: `linux`, `macos`, or `windows`."
  def test_the_three_operating_systems_are_linux_macos_and_windows
    assert_equal(%i[linux macos windows], Proof::OS.all.map(&:name))
  end

  # Glossary, "OS": "`linux`, `macos`, or `windows`", and project file reference,
  # "Children": "One or more of `linux`, `macos`, `windows`", written as the files write them.
  def test_a_name_is_read_from_a_string_or_a_symbol
    assert_same(:macos, Proof::OS.new(name: "macos").name)
    assert_same(:windows, Proof::OS.new(name: :windows).name)
  end

  # Two values with one name are one value, so lists of them compare.
  def test_two_operating_systems_with_one_name_are_equal
    assert_equal(Proof::OS.new(name: :linux), Proof::OS.new(name: "linux"))
  end

  # Messages name an operating system as the files write it.
  def test_the_name_is_written_as_the_files_write_it
    assert_equal("windows", Proof::OS.new(name: :windows).to_s)
  end

  # Project file reference, "Mistakes Proof catches": "an `os` node lists an
  # operating system other than `linux`, `macos`, or `windows`" is refused.
  def test_another_operating_system_is_refused
    names = %w[freebsd darwin win32 Linux LINUX] << "linux "

    names.each do |name|
      assert_raises(Proof::InvalidOSError, name) { Proof::OS.new(name:) }
    end
  end

  # Project file reference, "Children": `--os any` and `--os all` are words of
  # the flag. The glossary's three names are the only operating systems.
  def test_the_words_of_the_os_flag_are_not_operating_systems
    assert_raises(Proof::InvalidOSError) { Proof::OS.new(name: "any") }
    assert_raises(Proof::InvalidOSError) { Proof::OS.new(name: :all) }
  end

  # Glossary, "OS": the three names are the only operating systems, so no other type is one.
  def test_a_value_that_is_not_a_name_is_refused
    [nil, 1, [:linux], ""].each do |name|
      assert_raises(Proof::InvalidOSError) { Proof::OS.new(name:) }
    end
  end

  # The message says what an OS is and what it got.
  def test_the_message_names_the_value_and_the_three_operating_systems
    error = assert_raises(Proof::InvalidOSError) { Proof::OS.new(name: "darwin") }

    assert_equal('an OS is one of linux, macos, windows, not "darwin"', error.message)
  end

  # One base class catches every rule the domain refuses.
  def test_every_error_the_domain_raises_is_a_proof_error
    assert_operator(Proof::InvalidOSError, :<, Proof::Error)
  end
end
