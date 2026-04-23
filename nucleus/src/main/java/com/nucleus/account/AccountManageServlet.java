package com.nucleus.account;

import com.nucleus.util.DBConn;
import com.nucleus.util.PasswordUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/account-manage")
public class AccountManageServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String loginId = (String) request.getSession().getAttribute("loginId");
        Integer roleNumSession = (Integer) request.getSession().getAttribute("roleNum");
        if (loginId == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        if (roleNumSession == null || roleNumSession != 1) {
            response.sendRedirect("ad_check.jsp");
            return;
        }

        String action = request.getParameter("action");
        try {
            if ("create".equals(action)) {
                createAccount(request, response);
            } else if ("update".equals(action)) {
                updateAccount(request, response);
            } else if ("delete".equals(action)) {
                deleteAccount(request, response, loginId);
            } else {
                response.sendRedirect("account.jsp");
            }
        } catch (Exception e) {
            response.sendRedirect("account.jsp?error=" + encode(e.getMessage()));
        }
    }

    private void createAccount(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String userId = trim(request.getParameter("userId"));
        String userPw = trim(request.getParameter("userPw"));
        String userNum = trim(request.getParameter("userNum"));
        String roleNum = trim(request.getParameter("roleNum"));
        if (userId.isEmpty() || userPw.isEmpty() || userNum.isEmpty() || roleNum.isEmpty()) {
            response.sendRedirect("account.jsp?mode=create&error=" + encode("모든 항목을 입력해주세요."));
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBConn.getConnection();
            conn.setAutoCommit(false);

            pstmt = conn.prepareStatement("INSERT INTO nc_user (user_id, user_pw, user_num) VALUES (?, ?, ?)");
            pstmt.setString(1, userId);
            pstmt.setString(2, PasswordUtil.hash(userPw));
            pstmt.setInt(3, Integer.parseInt(userNum));
            pstmt.executeUpdate();
            DBConn.close(pstmt);
            pstmt = null;

            pstmt = conn.prepareStatement("INSERT INTO nc_user_role (user_id, role_num) VALUES (?, ?)");
            pstmt.setString(1, userId);
            pstmt.setInt(2, Integer.parseInt(roleNum));
            pstmt.executeUpdate();

            conn.commit();
            response.sendRedirect("account.jsp?success=" + encode("계정이 생성되었습니다."));
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            throw e;
        } finally {
            DBConn.close(pstmt);
            if (conn != null) {
                conn.setAutoCommit(true);
            }
            DBConn.close(conn);
        }
    }

    private void updateAccount(HttpServletRequest request, HttpServletResponse response) throws Exception {
        String userId = trim(request.getParameter("userId"));
        String userPw = trim(request.getParameter("userPw"));
        String userNum = trim(request.getParameter("userNum"));
        String roleNum = trim(request.getParameter("roleNum"));
        if (userId.isEmpty() || userNum.isEmpty() || roleNum.isEmpty()) {
            response.sendRedirect("account.jsp?mode=edit&userId=" + encode(userId) + "&error=" + encode("필수 항목이 누락되었습니다."));
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBConn.getConnection();
            conn.setAutoCommit(false);

            if (userPw.isEmpty()) {
                pstmt = conn.prepareStatement("UPDATE nc_user SET user_num = ? WHERE user_id = ?");
                pstmt.setInt(1, Integer.parseInt(userNum));
                pstmt.setString(2, userId);
            } else {
                pstmt = conn.prepareStatement("UPDATE nc_user SET user_pw = ?, user_num = ? WHERE user_id = ?");
                pstmt.setString(1, PasswordUtil.hash(userPw));
                pstmt.setInt(2, Integer.parseInt(userNum));
                pstmt.setString(3, userId);
            }
            pstmt.executeUpdate();
            DBConn.close(pstmt);
            pstmt = null;

            pstmt = conn.prepareStatement("SELECT COUNT(*) FROM nc_user_role WHERE user_id = ?");
            pstmt.setString(1, userId);
            rs = pstmt.executeQuery();
            boolean exists = false;
            if (rs.next()) {
                exists = rs.getInt(1) > 0;
            }
            DBConn.close(rs);
            DBConn.close(pstmt);
            rs = null;
            pstmt = null;

            if (exists) {
                pstmt = conn.prepareStatement("UPDATE nc_user_role SET role_num = ? WHERE user_id = ?");
                pstmt.setInt(1, Integer.parseInt(roleNum));
                pstmt.setString(2, userId);
            } else {
                pstmt = conn.prepareStatement("INSERT INTO nc_user_role (user_id, role_num) VALUES (?, ?)");
                pstmt.setString(1, userId);
                pstmt.setInt(2, Integer.parseInt(roleNum));
            }
            pstmt.executeUpdate();

            conn.commit();
            response.sendRedirect("account.jsp?success=" + encode("계정 정보가 수정되었습니다."));
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            throw e;
        } finally {
            DBConn.close(rs);
            DBConn.close(pstmt);
            if (conn != null) {
                conn.setAutoCommit(true);
            }
            DBConn.close(conn);
        }
    }

    private void deleteAccount(HttpServletRequest request, HttpServletResponse response, String loginId) throws Exception {
        String userId = trim(request.getParameter("userId"));
        if (userId.isEmpty()) {
            response.sendRedirect("account.jsp");
            return;
        }
        if (userId.equals(loginId)) {
            response.sendRedirect("account.jsp?error=" + encode("현재 로그인한 administrator 계정은 삭제할 수 없습니다."));
            return;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBConn.getConnection();
            conn.setAutoCommit(false);

            pstmt = conn.prepareStatement("DELETE FROM nc_user_role WHERE user_id = ?");
            pstmt.setString(1, userId);
            pstmt.executeUpdate();
            DBConn.close(pstmt);
            pstmt = null;

            pstmt = conn.prepareStatement("DELETE FROM nc_user WHERE user_id = ?");
            pstmt.setString(1, userId);
            pstmt.executeUpdate();

            conn.commit();
            response.sendRedirect("account.jsp?success=" + encode("계정이 삭제되었습니다."));
        } catch (Exception e) {
            if (conn != null) {
                conn.rollback();
            }
            throw e;
        } finally {
            DBConn.close(pstmt);
            if (conn != null) {
                conn.setAutoCommit(true);
            }
            DBConn.close(conn);
        }
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private String encode(String value) {
        return java.net.URLEncoder.encode(value == null ? "" : value, java.nio.charset.StandardCharsets.UTF_8);
    }
}
