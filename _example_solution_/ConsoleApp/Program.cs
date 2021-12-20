using System;
using System.Data.SqlClient;
using System.Text;
using System.Text.Json;

namespace Goo.Example
{
    public class Program
    {
        public static void Main(string[] args)
        {
            if(args.Length == 0)
                Usage();

            else if (String.Equals("load", args[0], StringComparison.OrdinalIgnoreCase)) 
                Load();

            else if (String.Equals("all", args[0], StringComparison.OrdinalIgnoreCase)) 
                GreetAll();

            else
                Usage();
            
        }

        static void Usage()
        {
            Console.WriteLine("Hello, World!");
            Console.WriteLine("");
            Console.WriteLine("Commands:");
            Console.WriteLine("---------");
            Console.WriteLine("load     Creates a SQL database and populates it with greetings");
            Console.WriteLine("all      Greets in a random language");
            Console.WriteLine("");
        }

        static void Load()
        {
            var tableData = JsonSerializer.Deserialize<LanguageData>(File.ReadAllText(@"..\Data\hello.json"));

            if(tableData == null || tableData.Data.Count == 0)
            {
                Console.WriteLine(@"No contained rows in ..\Data\hello.json");
                return;
            }

            SqlConnection conn;
            SqlCommand command;
            string sql;

            conn = new SqlConnection(Environment.GetEnvironmentVariable("GOO_DEV_CONNECTIONSTRING"));
            conn.Open();

            // Create table if not exist and remove rows
            sql =
                @"
                    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Hello]') AND type in (N'U'))
                    BEGIN
                        DROP TABLE [dbo].[Hello];
                    END;
                    CREATE TABLE [dbo].[Hello] (
                        [Lang] nvarchar(255),
                        [HelloPhrase] nvarchar(255)
                    );
                ";
            
            command = new SqlCommand(sql,conn);
            
            command.ExecuteNonQuery();

            // Insert the rows obtained from json file
            var sqlBuilder = new StringBuilder(@"INSERT INTO [dbo].[Hello] ([Lang],[HelloPhrase]) VALUES ");

            var rows = 0;
            foreach(var entry in tableData.Data)
            {
                sqlBuilder.Append(rows++ == 0 ? "" : ",");
                sqlBuilder.Append($"(N'{entry.Lang}',N'{entry.HelloPhrase}')");
            }

            sql = sqlBuilder.ToString();

            command = new SqlCommand(sql, conn);

            command.ExecuteNonQuery();

            // Clean up

            conn.Close();

            Console.WriteLine($"Loaded {rows} row(s).");

        }

        static void GreetAll()
        {
            SqlConnection conn;
            SqlCommand command;
            string sql;

            conn = new SqlConnection(Environment.GetEnvironmentVariable("GOO_DEV_CONNECTIONSTRING"));
            conn.Open();

            // Select a rondom row
            sql = @"SELECT TOP 1 [Lang], [HelloPhrase] FROM [dbo].[Hello] ORDER BY NEWID()";

            command = new SqlCommand(sql, conn);

            var reader = command.ExecuteReader();

            // Diplay result
            while (reader.Read())
            {
                Console.WriteLine($"{reader["HelloPhrase"]} (in {reader["Lang"]})" );
            }

            // Clean up

            conn.Close();
        }


        // DTO's

        private class LanguageData
        {
            public List<LanguageEntry> Data { get; set; } = new();
        }

        private class LanguageEntry
        {
            public string Lang { get; set; } = "";
            public string HelloPhrase { get; set; } = "";
        }

    }
  
}