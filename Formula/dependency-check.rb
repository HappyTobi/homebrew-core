class DependencyCheck < Formula
  desc "OWASP dependency-check"
  homepage "https://owasp.org/www-project-dependency-check/"
  url "https://github.com/jeremylong/DependencyCheck/releases/download/v7.4.0/dependency-check-7.4.0-release.zip"
  sha256 "6dee2bc9ac5e43a314681d480b619268cfd790e2faa3c7c25b95ac2d719574e5"
  license "Apache-2.0"

  livecheck do
    url :homepage
    regex(/href=.*?dependency-check[._-]v?(\d+(?:\.\d+)+)-release\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, all: "1459de128a28426913780b2af97e126da1a2c8781abf7b7aa1f4a5c26460baff"
  end

  depends_on "openjdk"

  def install
    rm_f Dir["bin/*.bat"]

    chmod 0755, "bin/dependency-check.sh"
    libexec.install Dir["*"]

    (bin/"dependency-check").write_env_script libexec/"bin/dependency-check.sh",
      JAVA_HOME: Formula["openjdk"].opt_prefix

    (var/"dependencycheck").mkpath
    libexec.install_symlink var/"dependencycheck" => "data"

    (etc/"dependencycheck").mkpath
    jar = "dependency-check-core-#{version}.jar"
    corejar = libexec/"lib/#{jar}"
    system "unzip", "-o", corejar, "dependencycheck.properties", "-d", libexec/"etc"
    (etc/"dependencycheck").install_symlink libexec/"etc/dependencycheck.properties"
  end

  test do
    # wait a random amount of time as multiple tests are being on different OS
    # the sleep 1 seconds to 30 seconds assists with the NVD Rate Limiting issues
    sleep(rand(1..30))
    output = shell_output("#{bin}/dependency-check --version").strip
    assert_match "Dependency-Check Core version #{version}", output

    (testpath/"temp-props.properties").write <<~EOS
      cve.startyear=2017
      analyzer.assembly.enabled=false
    EOS
    system bin/"dependency-check", "-P", "temp-props.properties", "-f", "XML",
               "--project", "dc", "-s", libexec, "-d", testpath, "-o", testpath,
               "--cveUrlBase", "https://jeremylong.github.io/DependencyCheck/hb_nvd/nvdcve-1.1-%d.json.gz",
               "--cveUrlModified", "https://jeremylong.github.io/DependencyCheck/hb_nvd/nvdcve-1.1-modified.json.gz",
               "--cveStartYear", Time.now.year, "--cveDownloadWait", "5000"
    assert_predicate testpath/"dependency-check-report.xml", :exist?
  end
end
