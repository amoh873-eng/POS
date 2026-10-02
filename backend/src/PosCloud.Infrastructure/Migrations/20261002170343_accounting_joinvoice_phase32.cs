using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PosCloud.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class accounting_joinvoice_phase32 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceActivityNumber",
                table: "tenant_settings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceClientId",
                table: "tenant_settings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "JoInvoiceEnabled",
                table: "tenant_settings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceEnvironment",
                table: "tenant_settings",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceSecretKey",
                table: "tenant_settings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceQrCode",
                table: "sales",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceResponse",
                table: "sales",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceStatus",
                table: "sales",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "JoInvoiceUuid",
                table: "sales",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Address",
                table: "customers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NationalId",
                table: "customers",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TaxId",
                table: "customers",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "accounts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TenantId = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "text", nullable: false),
                    NameAr = table.Column<string>(type: "text", nullable: false),
                    NameEn = table.Column<string>(type: "text", nullable: false),
                    Type = table.Column<string>(type: "text", nullable: false),
                    ParentId = table.Column<Guid>(type: "uuid", nullable: true),
                    IsGroup = table.Column<bool>(type: "boolean", nullable: false),
                    Balance = table.Column<decimal>(type: "numeric", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_accounts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_accounts_accounts_ParentId",
                        column: x => x.ParentId,
                        principalTable: "accounts",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "journal_entries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TenantId = table.Column<Guid>(type: "uuid", nullable: false),
                    Date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    ReferenceType = table.Column<string>(type: "text", nullable: true),
                    ReferenceId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_journal_entries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "journal_entry_lines",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    JournalEntryId = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    Debit = table.Column<decimal>(type: "numeric", nullable: false),
                    Credit = table.Column<decimal>(type: "numeric", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_journal_entry_lines", x => x.Id);
                    table.ForeignKey(
                        name: "FK_journal_entry_lines_journal_entries_JournalEntryId",
                        column: x => x.JournalEntryId,
                        principalTable: "journal_entries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_sales_CustomerId",
                table: "sales",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_sales_JoInvoiceUuid",
                table: "sales",
                column: "JoInvoiceUuid",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_purchases_SupplierId",
                table: "purchases",
                column: "SupplierId");

            migrationBuilder.CreateIndex(
                name: "IX_accounts_ParentId",
                table: "accounts",
                column: "ParentId");

            migrationBuilder.CreateIndex(
                name: "IX_accounts_TenantId_Code",
                table: "accounts",
                columns: new[] { "TenantId", "Code" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_journal_entry_lines_JournalEntryId",
                table: "journal_entry_lines",
                column: "JournalEntryId");

            migrationBuilder.AddForeignKey(
                name: "FK_purchases_suppliers_SupplierId",
                table: "purchases",
                column: "SupplierId",
                principalTable: "suppliers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_sales_customers_CustomerId",
                table: "sales",
                column: "CustomerId",
                principalTable: "customers",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_purchases_suppliers_SupplierId",
                table: "purchases");

            migrationBuilder.DropForeignKey(
                name: "FK_sales_customers_CustomerId",
                table: "sales");

            migrationBuilder.DropTable(
                name: "accounts");

            migrationBuilder.DropTable(
                name: "journal_entry_lines");

            migrationBuilder.DropTable(
                name: "journal_entries");

            migrationBuilder.DropIndex(
                name: "IX_sales_CustomerId",
                table: "sales");

            migrationBuilder.DropIndex(
                name: "IX_sales_JoInvoiceUuid",
                table: "sales");

            migrationBuilder.DropIndex(
                name: "IX_purchases_SupplierId",
                table: "purchases");

            migrationBuilder.DropColumn(
                name: "JoInvoiceActivityNumber",
                table: "tenant_settings");

            migrationBuilder.DropColumn(
                name: "JoInvoiceClientId",
                table: "tenant_settings");

            migrationBuilder.DropColumn(
                name: "JoInvoiceEnabled",
                table: "tenant_settings");

            migrationBuilder.DropColumn(
                name: "JoInvoiceEnvironment",
                table: "tenant_settings");

            migrationBuilder.DropColumn(
                name: "JoInvoiceSecretKey",
                table: "tenant_settings");

            migrationBuilder.DropColumn(
                name: "JoInvoiceQrCode",
                table: "sales");

            migrationBuilder.DropColumn(
                name: "JoInvoiceResponse",
                table: "sales");

            migrationBuilder.DropColumn(
                name: "JoInvoiceStatus",
                table: "sales");

            migrationBuilder.DropColumn(
                name: "JoInvoiceUuid",
                table: "sales");

            migrationBuilder.DropColumn(
                name: "Address",
                table: "customers");

            migrationBuilder.DropColumn(
                name: "NationalId",
                table: "customers");

            migrationBuilder.DropColumn(
                name: "TaxId",
                table: "customers");
        }
    }
}
