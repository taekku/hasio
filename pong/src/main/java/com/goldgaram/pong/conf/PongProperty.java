package com.goldgaram.pong.conf;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pong")
public class PongProperty {
  private String distDirectory;
  /**
   * @return the distDirectory
   */
  public String getDistDirectory() {
      return distDirectory;
  }

  /**
   * @param distDirectory the distDirectory to set
   */
  public void setDistDirectory(String distDirectory) {
      this.distDirectory = distDirectory;
  }
}