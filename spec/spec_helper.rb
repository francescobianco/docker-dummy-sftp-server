RSpec.configure do |config|
  def file_fixture(filename)
    File.read(File.expand_path(__dir__+"/fixtures/files/#{filename}"))
  end
end
