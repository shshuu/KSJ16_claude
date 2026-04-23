<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,java.util.ArrayList,java.util.List,com.nucleus.util.DBConn" %>
<%
String loginId = (String) session.getAttribute("loginId");
Integer roleNum = (Integer) session.getAttribute("roleNum");
if (loginId == null) {
    response.sendRedirect("login.jsp");
    return;
}
if (roleNum == null || (roleNum != 1 && roleNum != 2)) {
    response.sendRedirect("ad_check.jsp");
    return;
}

List<String[]> assets = new ArrayList<String[]>();
String errorMessage = null;
Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    conn = DBConn.getConnection();
    pstmt = conn.prepareStatement(
        "SELECT asset_id, asset_name, asset_ip, status, last_updated " +
        "FROM nc_assets ORDER BY asset_id ASC"
    );
    rs = pstmt.executeQuery();

    while (rs.next()) {
        assets.add(new String[] {
            String.valueOf(rs.getInt("asset_id")),
            rs.getString("asset_name"),
            rs.getString("asset_ip"),
            rs.getString("status"),
            String.valueOf(rs.getTimestamp("last_updated"))
        });
    }
} catch (Exception e) {
    errorMessage = e.getMessage();
} finally {
    DBConn.close(rs);
    DBConn.close(pstmt);
    DBConn.close(conn);
}
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>자산 현황</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">자산 현황 페이지</h1>
        <p class="page-subtitle">`nc_assets(asset_id, asset_name, asset_ip, status, last_updated)` 조회 결과입니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-ghost" onclick="location.href='admin.jsp'">관리자 메인</button>
      </div>
    </header>
    <section class="table-card">
      <table>
        <thead>
          <tr><th>자산 번호</th><th>자산명</th><th>IP</th><th>상태</th><th>최근 갱신일</th></tr>
        </thead>
        <tbody>
          <%
          if (errorMessage != null) {
          %>
          <tr><td colspan="5">DB 조회 중 오류가 발생했습니다.</td></tr>
          <%
          } else if (assets.isEmpty()) {
          %>
          <tr><td colspan="5">등록된 자산 정보가 없습니다.</td></tr>
          <%
          } else {
              for (String[] asset : assets) {
          %>
          <tr>
            <td><%= asset[0] %></td>
            <td><%= asset[1] %></td>
            <td><%= asset[2] %></td>
            <td><%= asset[3] %></td>
            <td><%= asset[4] %></td>
          </tr>
          <%
              }
          }
          %>
        </tbody>
      </table>
    </section>
  </div>
</body>
</html>
