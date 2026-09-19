import { useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { useQueryClient } from "@tanstack/react-query";
import { Download, Upload, Database, Loader2, AlertTriangle } from "lucide-react";

// Order matters: parents first so foreign keys resolve on import
const BACKUP_TABLES = [
  "sports",
  "teams",
  "tournaments",
  "tournament_venues",
  "matches",
  "match_innings",
  "match_playing_xi",
  "match_substitutions",
  "match_api_scores",
  "tournament_points_table",
  "streaming_servers",
  "streaming_json_sources",
  "saved_streaming_servers",
  "channels",
  "channel_streaming_servers",
  "events",
  "event_streaming_servers",
  "banners",
  "sponsor_notices",
  "dynamic_pages",
  "custom_menus",
  "bottom_nav_items",
  "site_settings",
  "cricket_series",
  "football_leagues",
  "roles",
  "role_permissions",
  "custom_role_permissions",
] as const;

type BackupTable = (typeof BACKUP_TABLES)[number];

interface BackupFile {
  version: number;
  exported_at: string;
  tables: Record<string, any[]>;
}

const PAGE_SIZE = 1000;

const BackupManager = () => {
  const { toast } = useToast();
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [exporting, setExporting] = useState(false);
  const [importing, setImporting] = useState(false);
  const [progress, setProgress] = useState(0);
  const [currentTable, setCurrentTable] = useState<string>("");
  const [pendingBackup, setPendingBackup] = useState<BackupFile | null>(null);
  const [lastSummary, setLastSummary] = useState<string[]>([]);

  const handleExport = async () => {
    setExporting(true);
    setProgress(0);
    setLastSummary([]);
    const tables: Record<string, any[]> = {};
    const summary: string[] = [];

    try {
      for (let i = 0; i < BACKUP_TABLES.length; i++) {
        const table = BACKUP_TABLES[i];
        setCurrentTable(table);
        const rows: any[] = [];
        let from = 0;

        while (true) {
          const { data, error } = await supabase
            .from(table as BackupTable)
            .select("*")
            .range(from, from + PAGE_SIZE - 1);

          if (error) throw new Error(`${table}: ${error.message}`);
          rows.push(...(data || []));
          if (!data || data.length < PAGE_SIZE) break;
          from += PAGE_SIZE;
        }

        tables[table] = rows;
        summary.push(`${table}: ${rows.length}`);
        setProgress(Math.round(((i + 1) / BACKUP_TABLES.length) * 100));
      }

      const backup: BackupFile = {
        version: 1,
        exported_at: new Date().toISOString(),
        tables,
      };

      const blob = new Blob([JSON.stringify(backup, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `site-backup-${new Date().toISOString().slice(0, 19).replace(/[:T]/g, "-")}.json`;
      a.click();
      URL.revokeObjectURL(url);

      setLastSummary(summary);
      toast({ title: "Backup downloaded", description: "All site data exported successfully." });
    } catch (err: any) {
      toast({ title: "Export failed", description: err.message, variant: "destructive" });
    } finally {
      setExporting(false);
      setCurrentTable("");
    }
  };

  const handleFileSelected = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;

    try {
      const parsed = JSON.parse(await file.text()) as BackupFile;
      if (!parsed?.tables || typeof parsed.tables !== "object") {
        throw new Error("Invalid backup file format");
      }
      setPendingBackup(parsed);
    } catch (err: any) {
      toast({ title: "Invalid file", description: err.message, variant: "destructive" });
    }
  };

  const runImport = async () => {
    if (!pendingBackup) return;
    const backup = pendingBackup;
    setPendingBackup(null);
    setImporting(true);
    setProgress(0);
    setLastSummary([]);
    const summary: string[] = [];

    try {
      for (let i = 0; i < BACKUP_TABLES.length; i++) {
        const table = BACKUP_TABLES[i];
        setCurrentTable(table);
        const rows = backup.tables[table];
        setProgress(Math.round(((i + 1) / BACKUP_TABLES.length) * 100));

        if (!Array.isArray(rows) || rows.length === 0) continue;

        for (let j = 0; j < rows.length; j += 200) {
          const chunk = rows.slice(j, j + 200);
          const { error } = await supabase
            .from(table as BackupTable)
            .upsert(chunk as any, { onConflict: "id" });
          if (error) throw new Error(`${table}: ${error.message}`);
        }

        summary.push(`${table}: ${rows.length}`);
      }

      setLastSummary(summary);
      await queryClient.invalidateQueries();
      toast({ title: "Backup restored", description: "Data imported successfully." });
    } catch (err: any) {
      toast({ title: "Import failed", description: err.message, variant: "destructive" });
    } finally {
      setImporting(false);
      setCurrentTable("");
    }
  };

  const busy = exporting || importing;

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="w-5 h-5" />
            Backup &amp; Restore
          </CardTitle>
          <CardDescription>
            Download a full copy of your site data as a JSON file, or restore it from a previous backup.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-wrap gap-3">
            <Button variant="gradient" onClick={handleExport} disabled={busy}>
              {exporting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
              Export Backup
            </Button>
            <Button variant="outline" onClick={() => fileInputRef.current?.click()} disabled={busy}>
              {importing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />}
              Import Backup
            </Button>
            <input
              ref={fileInputRef}
              type="file"
              accept="application/json,.json"
              className="hidden"
              onChange={handleFileSelected}
            />
          </div>

          {busy && (
            <div className="space-y-2">
              <Progress value={progress} />
              <p className="text-sm text-muted-foreground">
                {exporting ? "Exporting" : "Importing"} {currentTable}… {progress}%
              </p>
            </div>
          )}

          {!busy && lastSummary.length > 0 && (
            <div className="flex flex-wrap gap-2 pt-2">
              {lastSummary.map((s) => (
                <Badge key={s} variant="secondary" className="text-xs">
                  {s}
                </Badge>
              ))}
            </div>
          )}

          <div className="rounded-lg border border-border bg-muted/40 p-3 text-sm text-muted-foreground">
            <p className="flex items-start gap-2">
              <AlertTriangle className="w-4 h-4 mt-0.5 shrink-0" />
              <span>
                Importing overwrites existing records that share the same ID and adds any missing ones.
                Users, roles assignments and passwords are not part of this backup.
              </span>
            </p>
          </div>
        </CardContent>
      </Card>

      <AlertDialog open={!!pendingBackup} onOpenChange={(open) => !open && setPendingBackup(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Restore this backup?</AlertDialogTitle>
            <AlertDialogDescription>
              {pendingBackup
                ? `This file was created on ${new Date(pendingBackup.exported_at).toLocaleString()}. Existing records with matching IDs will be overwritten.`
                : ""}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={runImport}>Restore</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default BackupManager;
