<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection,java.sql.PreparedStatement,java.sql.ResultSet,java.util.ArrayList,java.util.List,java.net.URLDecoder,com.nucleus.util.DBConn" %>
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

int pageNo = 1;
int pageSize = 10;
try {
    pageNo = Integer.parseInt(request.getParameter("page"));
    if (pageNo < 1) {
        pageNo = 1;
    }
} catch (Exception ignored) {
}

String successMessage = request.getParameter("success");
if (successMessage != null) {
    successMessage = URLDecoder.decode(successMessage, "UTF-8");
}

int offset = (pageNo - 1) * pageSize;
List<String[]> posts = new ArrayList<String[]>();
int totalCount = 0;
String errorMessage = null;

Connection conn = null;
PreparedStatement countStmt = null;
PreparedStatement listStmt = null;
ResultSet countRs = null;
ResultSet listRs = null;

try {
    conn = DBConn.getConnection();
    countStmt = conn.prepareStatement("SELECT COUNT(*) FROM nc_notice");
    countRs = countStmt.executeQuery();
    if (countRs.next()) {
        totalCount = countRs.getInt(1);
    }

    listStmt = conn.prepareStatement(
        "SELECT nt_id, user_id, title, created_at FROM nc_notice ORDER BY nt_id DESC LIMIT ? OFFSET ?"
    );
    listStmt.setInt(1, pageSize);
    listStmt.setInt(2, offset);
    listRs = listStmt.executeQuery();

    while (listRs.next()) {
        posts.add(new String[] {
            String.valueOf(listRs.getInt("nt_id")),
            listRs.getString("title"),
            listRs.getString("user_id"),
            String.valueOf(listRs.getTimestamp("created_at"))
        });
    }
} catch (Exception e) {
    errorMessage = e.getMessage();
} finally {
    DBConn.close(listRs);
    DBConn.close(countRs);
    DBConn.close(listStmt);
    DBConn.close(countStmt);
    DBConn.close(conn);
}

int totalPages = Math.max(1, (int) Math.ceil(totalCount / (double) pageSize));
%>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>관리자 게시판 목록</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="page-shell">
    <header class="layout-header">
      <div>
        <h1 class="page-title">관리자 게시판 목록</h1>
        <p class="page-subtitle">일반 사용자 게시판과 분리된 관리자용 목록입니다. 표시 내용은 동일하지만 관리 기능으로 연결됩니다.</p>
      </div>
      <div class="top-actions">
        <button class="btn btn-primary" onclick="location.href='board_write.jsp'">글 작성</button>
        <button class="btn btn-ghost" onclick="location.href='main.jsp'">메인으로</button>
        <button class="btn btn-ghost" onclick="location.href='admin.jsp'">관리자 메인</button>
      </div>
    </header>

    <% if (successMessage != null) { %>
    <div class="notice" style="margin-bottom:20px;"><%= successMessage %></div>
    <% } %>

    <section class="table-card">
      <table>
        <thead>
          <tr>
            <th>번호</th>
            <th>제목</th>
            <th>작성자</th>
            <th>작성일</th>
          </tr>
        </thead>
        <tbody>
          <%
          if (errorMessage != null) {
          %>
          <tr><td colspan="4">DB 조회 중 오류가 발생했습니다.</td></tr>
          <%
          } else if (posts.isEmpty()) {
          %>
          <tr><td colspan="4">등록된 게시글이 없습니다.</td></tr>
          <%
          } else {
              for (int idx = 0; idx < posts.size(); idx++) {
                  String[] post = posts.get(idx);
                  int displayNo = offset + idx + 1;
          %>
          <tr>
            <td><%= displayNo %></td>
            <td><a href="board_admin.jsp?postId=<%= post[0] %>"><%= post[1] %></a></td>
            <td><%= post[2] %></td>
            <td><%= post[3] %></td>
          </tr>
          <%
              }
          }
          %>
        </tbody>
      </table>
    </section>

    <div class="pagination">
      <%
      for (int i = 1; i <= totalPages; i++) {
      %>
      <a class="page-pill <%= i == pageNo ? "active" : "" %>" href="board_list_admin.jsp?page=<%= i %>"><%= i %></a>
      <%
      }
      %>
    </div>
  </div>
</body>
</html>
