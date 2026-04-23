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
String assetErrorMessage = null;
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
    assetErrorMessage = e.getMessage();
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
  <title>관리자 페이지</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">관리자 페이지</h1>
        <p class="page-subtitle">자산 현황은 첫 화면에서 바로 확인하고, 아래에서 계정과 게시판 관리로 이어집니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-ghost" onclick="location.href='main.jsp'">메인으로</button>
      </div>
    </header>

    <section class="monitoring-panel monitoring-panel-admin">
      <div class="monitoring-copy">
        <span class="panel-label">ASSET MONITORING</span>
        <h2>자산 현황</h2>
        <p class="muted">관리자 첫 화면에서 주요 자산 상태와 최근 갱신 시간을 바로 확인할 수 있도록 배치했습니다.</p>
      </div>
      <div class="asset-preview-card">
        <div class="asset-preview-head">
          <strong>운영 자산 목록</strong>
          <button class="btn btn-ghost" type="button" onclick="location.href='asset.jsp'">상세 보기</button>
        </div>
        <div class="asset-preview-table">
          <table>
            <thead>
              <tr>
                <th>자산 번호</th>
                <th>자산명</th>
                <th>IP</th>
                <th>상태</th>
                <th>최근 갱신</th>
              </tr>
            </thead>
            <tbody>
              <%
              if (assetErrorMessage != null) {
              %>
              <tr><td colspan="5">자산 정보를 불러오는 중 오류가 발생했습니다.</td></tr>
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
                <td><span class="status-badge"><%= asset[3] %></span></td>
                <td><%= asset[4] %></td>
              </tr>
              <%
                  }
              }
              %>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <section class="content-stack">
      <% if (roleNum == 1) { %>
      <a class="tile feature-link" href="account.jsp">
        <div>
          <h3>계정 목록</h3>
          <p class="muted">계정 생성, 수정, 삭제 기능을 한 흐름으로 이어서 관리할 수 있습니다.</p>
        </div>
        <span class="feature-arrow">&rarr;</span>
      </a>
      <% } %>
      <a class="tile feature-link" href="board_list_admin.jsp">
        <div>
          <h3>게시판 관리</h3>
          <p class="muted">관리자 전용 게시판 화면으로 이동해 게시글과 관리 기능을 함께 확인합니다.</p>
        </div>
        <span class="feature-arrow">&rarr;</span>
      </a>
    </section>
  </div>
</body>
</html>
