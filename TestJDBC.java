import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class TestJDBC {
    public static void main(String[] args) {
        String url = "jdbc:postgresql://localhost:5432/SGIM2";
        String user = "sgiri_app";
        String password = "sgim123";

        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {

            System.out.println("Connected.");
            ResultSet rs = stmt.executeQuery("SELECT count(*) FROM reportes.vw_resumen_tickets");
            if (rs.next()) {
                System.out.println("Count: " + rs.getInt(1));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
