package com.goldgaram.pong.service;

import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Repository;
import com.goldgaram.pong.db.common.dao.AbstractDAO;

@Repository("orgMapper")
public class OrgMapper extends AbstractDAO {
  public List<Map<String, Object>> selectOrgList(){
    return (List<Map<String, Object>>)selectList("pingpong.db.org.Org.getOrgTree");
  }

}