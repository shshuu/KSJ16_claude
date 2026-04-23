<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>로그인</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="auth-shell">
    <section class="auth-card">
      <h1 class="page-title">통합 관리 포털</h1>
      <p class="page-subtitle">아이디/비밀번호를 받아 `id_check.jsp`에서 회원 여부를 확인합니다.</p>
      <form class="form-grid" action="id_check.jsp" method="post">
        <div class="field">
          <label for="userId">아이디</label>
          <input id="userId" name="userId" required>
        </div>
        <div class="field">
          <label for="userPw">비밀번호</label>
          <input id="userPw" name="userPw" type="password" required>
        </div>
        <div class="actions">
          <button class="btn btn-primary" type="submit">로그인</button>
        </div>
      </form>
    </section>
  </div>
</body>
</html>
