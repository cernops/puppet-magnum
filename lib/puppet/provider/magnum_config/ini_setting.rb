Puppet::Type.type(:magnum_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:teigi_ini_setting).provider(:ini_setting)
) do

  # the setting is always default
  # this if for backwards compat with the old puppet providers for nova_config
  def section
    resource[:name].split('/', 2)[0]
  end

  # assumes that the name was the setting
  # this is to maintain backwards compat with the the older
  # stuff
  def setting
    resource[:name].split('/', 2)[1]
  end

  def separator
    '='
  end

  def getvalue
    if resource[:secret] == :true
      dirpath = '/var/lib/puppet/tbag' # FIXME should be var
      f = [dirpath, resource[:value]].join("/")
      unless File.file?(f)
        self.fail "teigisecret[\"#{resource[:value]}\"] does not exist"
      end
      contents = File.open(f, &:readline).chomp
      return contents
    else
      return resource[:value]
    end
  end

  def self.file_path
    '/etc/magnum/magnum.conf'
  end

  # this needs to be removed. This has been replaced with the class method
  def file_path
    self.class.file_path
  end

end
