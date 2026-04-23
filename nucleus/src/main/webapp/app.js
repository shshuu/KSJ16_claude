const sessionKey = { role: "demoRole", user: "demoUserId" };
const boardPosts = [
  { id: 101, title: "4월 자산 점검 안내", author: "admin", date: "2026-04-15", views: 31, file: "asset-report.pdf" },
  { id: 100, title: "게시판 운영 정책", author: "admin", date: "2026-04-13", views: 44, file: "policy.docx" },
  { id: 99, title: "서버 점검 공지", author: "ops", date: "2026-04-11", views: 28, file: "maintenance.xlsx" }
];

function getRole() {
  return localStorage.getItem(sessionKey.role) || "standard";
}

function getUserId() {
  return localStorage.getItem(sessionKey.user) || "guest";
}

function setSession(id, role) {
  localStorage.setItem(sessionKey.user, id);
  localStorage.setItem(sessionKey.role, role);
}

function clearSession() {
  localStorage.removeItem(sessionKey.user);
  localStorage.removeItem(sessionKey.role);
}

function requireLogin() {
  if (!localStorage.getItem(sessionKey.user)) {
    location.href = "login.html";
    return false;
  }
  return true;
}

function isManagerRole(role = getRole()) {
  return role === "mini_admin" || role === "administrator";
}

function getRoleLabel(role = getRole()) {
  if (role === "administrator") return "Administrator";
  if (role === "mini_admin") return "Mini_Admin";
  return "Standard";
}

function updateRoleUI() {
  const role = getRole();
  document.querySelectorAll("[data-role-label]").forEach((node) => {
    node.textContent = getRoleLabel(role);
  });
  document.querySelectorAll("[data-user-label]").forEach((node) => {
    node.textContent = getUserId();
  });
  document.querySelectorAll("[data-admin-only]").forEach((node) => {
    node.hidden = !isManagerRole(role);
  });
}

function goAdminPage() {
  if (!isManagerRole()) {
    alert("관리자 권한 계정만 접근할 수 있습니다.");
    return;
  }
  location.href = "admin.html";
}

function openBoardPost(id) {
  localStorage.setItem("selectedPostId", String(id));
  location.href = isManagerRole() ? "board_admin.html" : "board_view.html";
}

function renderBoardTable(targetId) {
  const body = document.getElementById(targetId);
  if (!body) return;
  body.innerHTML = boardPosts.map((post) => `
    <tr>
      <td>${post.id}</td>
      <td><a href="#" onclick="openBoardPost(${post.id}); return false;">${post.title}</a></td>
      <td>${post.author}</td>
      <td>${post.date}</td>
      <td>${post.views}</td>
    </tr>`).join("");
}

function getSelectedPost() {
  const id = Number(localStorage.getItem("selectedPostId") || boardPosts[0].id);
  return boardPosts.find((post) => post.id === id) || boardPosts[0];
}

function renderBoardView() {
  const post = getSelectedPost();
  document.querySelectorAll("[data-post-title]").forEach((node) => {
    node.textContent = post.title;
  });
  document.querySelectorAll("[data-post-id]").forEach((node) => {
    node.textContent = post.id;
  });
  document.querySelectorAll("[data-post-author]").forEach((node) => {
    node.textContent = post.author;
  });
  document.querySelectorAll("[data-post-date]").forEach((node) => {
    node.textContent = post.date;
  });
  document.querySelectorAll("[data-post-file]").forEach((node) => {
    node.textContent = post.file;
  });
}

document.addEventListener("DOMContentLoaded", updateRoleUI);
