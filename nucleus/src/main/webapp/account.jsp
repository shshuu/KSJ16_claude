<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,java.util.ArrayList,java.util.List,java.net.URLDecoder,com.nucleus.util.DBConn" %>
<%
String loginId = (String) session.getAttribute("loginId");
Integer roleNum = (Integer) session.getAttribute("roleNum");
if (loginId == null) {
    response.sendRedirect("login.jsp");
    return;
}
if (roleNum == null || roleNum != 1) {
    response.sendRedirect("ad_check.jsp");
    return;
}

String mode = request.getParameter("mode");
String selectedUserId = request.getParameter("userId");
String successMessage = request.getParameter("success");
String errorMessage = request.getParameter("error");
if (successMessage != null) {
    successMessage = URLDecoder.decode(successMessage, "UTF-8");
}
if (errorMessage != null) {
    errorMessage = URLDecoder.decode(errorMessage, "UTF-8");
}

List<String[]> users = new ArrayList<String[]>();
List<String[]> roles = new ArrayList<String[]>();
String formUserId = "";
String formUserPw = "";
String formUserNum = "";
String formRoleNum = "";

Connection conn = null;
PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    conn = DBConn.getConnection();

    pstmt = conn.prepareStatement(
        "SELECT u.user_id, u.user_num, ur.role_num, r.role_description " +
        "FROM nc_user u " +
        "LEFT JOIN nc_user_role ur ON ur.user_id = u.user_id " +
        "LEFT JOIN nc_role r ON r.role_num = ur.role_num " +
        "ORDER BY u.user_num ASC"
    );
    rs = pstmt.executeQuery();
    while (rs.next()) {
        users.add(new String[] {
            rs.getString("user_id"),
            String.valueOf(rs.getInt("user_num")),
            String.valueOf(rs.getInt("role_num")),
            rs.getString("role_description")
        });
    }
    DBConn.close(rs);
    DBConn.close(pstmt);
    rs = null;
    pstmt = null;

    pstmt = conn.prepareStatement("SELECT role_num, role_description FROM nc_role ORDER BY role_num ASC");
    rs = pstmt.executeQuery();
    while (rs.next()) {
        roles.add(new String[] {
            String.valueOf(rs.getInt("role_num")),
            rs.getString("role_description")
        });
    }
    DBConn.close(rs);
    DBConn.close(pstmt);
    rs = null;
    pstmt = null;

    if ("edit".equals(mode) && selectedUserId != null && !selectedUserId.trim().isEmpty()) {
        pstmt = conn.prepareStatement(
            "SELECT u.user_id, u.user_num, ur.role_num " +
            "FROM nc_user u " +
            "LEFT JOIN nc_user_role ur ON ur.user_id = u.user_id " +
            "WHERE u.user_id = ?"
        );
        pstmt.setString(1, selectedUserId);
        rs = pstmt.executeQuery();
        if (rs.next()) {
            formUserId = rs.getString("user_id");
            formUserNum = String.valueOf(rs.getInt("user_num"));
            formRoleNum = String.valueOf(rs.getInt("role_num"));
        }
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
  <title>계정 목록</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">계정 목록</h1>
        <p class="page-subtitle">사용자와 권한 매핑을 함께 관리합니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-primary" type="button" onclick="location.href='account.jsp?mode=create'">계정 생성</button>
        <button class="btn btn-ghost" onclick="location.href='admin.jsp'">관리자 메인</button>
      </div>
    </header>

    <% if (successMessage != null) { %>
    <div class="notice" style="margin-bottom:20px;"><%= successMessage %></div>
    <% } %>
    <% if (errorMessage != null) { %>
    <div class="notice" style="margin-bottom:20px; background:#fee4e2; color:#b42318; border-color:#f6c7c3;"><%= errorMessage %></div>
    <% } %>

    <% if ("create".equals(mode) || "edit".equals(mode)) { %>
    <section class="card" style="margin-bottom:20px;">
      <h2 class="section-title"><%= "edit".equals(mode) ? "계정 수정" : "계정 생성" %></h2>
      <form class="form-grid" method="post" action="account-manage">
        <input type="hidden" name="action" value="<%= "edit".equals(mode) ? "update" : "create" %>">
        <div class="field">
          <label for="userId">아이디</label>
          <input id="userId" name="userId" value="<%= formUserId %>" <%= "edit".equals(mode) ? "readonly" : "" %> required>
        </div>
        <div class="field">
          <label for="userPw">비밀번호 <%= "edit".equals(mode) ? "(변경 시에만 입력)" : "" %></label>
          <input id="userPw" name="userPw" type="password" value="<%= formUserPw %>" <%= "edit".equals(mode) ? "" : "required" %>>
        </div>
        <div class="field">
          <label for="userNum">사용자 번호</label>
          <input id="userNum" name="userNum" type="number" value="<%= formUserNum %>" required>
        </div>
        <div class="field">
          <label for="roleNum">권한</label>
          <select id="roleNum" name="roleNum" required>
            <option value="">권한을 선택하세요</option>
            <%
            for (String[] role : roles) {
            %>
            <option value="<%= role[0] %>" <%= role[0].equals(formRoleNum) ? "selected" : "" %>><%= role[0] %> - <%= role[1] %></option>
            <%
            }
            %>
          </select>
        </div>
        <div class="actions">
          <button class="btn btn-primary" type="submit"><%= "edit".equals(mode) ? "수정 저장" : "계정 생성" %></button>
          <button class="btn btn-ghost" type="button" onclick="location.href='account.jsp'">취소</button>
        </div>
      </form>
    </section>
    <% } %>

    <section class="table-card">
      <table>
        <thead>
          <tr>
            <th>아이디</th>
            <th>사용자 번호</th>
            <th>권한 번호</th>
            <th>권한명</th>
            <th>관리</th>
          </tr>
        </thead>
        <tbody>
          <%
          if (users.isEmpty()) {
          %>
          <tr><td colspan="5">등록된 계정 정보가 없습니다.</td></tr>
          <%
          } else {
              for (String[] user : users) {
          %>
          <tr>
            <td><%= user[0] %></td>
            <td><%= user[1] %></td>
            <td><%= user[2] %></td>
            <td><%= user[3] == null ? "-" : user[3] %></td>
            <td class="inline-actions">
              <button class="btn btn-ghost" type="button" onclick="location.href='account.jsp?mode=edit&userId=<%= user[0] %>'">수정</button>
              <form method="post" action="account-manage" onsubmit="return confirm('이 계정을 삭제하시겠습니까?');">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="userId" value="<%= user[0] %>">
                <button class="btn btn-danger" type="submit">삭제</button>
              </form>
            </td>
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
