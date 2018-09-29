<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="Newtonsoft.Json" %>

<%@ Page Language="C#" %>

<!DOCTYPE html>
<html>
<head>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
    <script runat="server">

        class MemoryStats
        {
            public string Info { get; set; }
            public string GCTotal { get; set; }
            public string WorkingSet { get; set; }
            public string PrivateMem { get; set; }
            public string VirtualMem { get; set; }
            public string PagedMem { get; set; }
            public string PagedSystemMem { get; set; }
            public string NonPagedSystemMem { get; set; }
            public string Handles { get; set; }
            public string Modules { get; set; }
            public string Threads { get; set; }
            public string ProcessorTime { get; set; }
            public string ProcessorAffinity { get; set; }
        }
        protected override void OnPreLoad(EventArgs e)
        {
            switch (Request.Form["op"])
            {
                case "GetMemoryStats":
                    Response.Clear();
                    Response.Write(GetMemoryStats());
                    Response.End();
                    break;
                case "GetPeakMemoryStats":
                    Response.Clear();
                    Response.Write(GetMemoryPeakStats());
                    Response.End();
                    break;
                case "ForceGC":
                    Response.Clear();
                    ForceGC();
                    Response.Write(JsonSerializeObject(new MemoryStats { Info = "<span style=color:blue>Garbage Collected</span>" }));
                    Response.End();
                    break;
            }
        }

        private string JsonSerializeObject(object obj)
        {
            return JsonConvert.SerializeObject(obj, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
        }

        private void ForceGC()
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
        }

        private string GetMemoryStats()
        {
            var process = Process.GetCurrentProcess();
            var bytes1 = GC.GetTotalMemory(false);
            var bytes2 = GC.GetTotalMemory(true); // force 
            var memoryStat = new MemoryStats
            {
                GCTotal = bytes1.ToString("#,#") + " - " + bytes2.ToString("#,#"),
                WorkingSet = process.WorkingSet64.ToString("#,#"),
                PrivateMem = process.PrivateMemorySize64.ToString("#,#"),
                VirtualMem = process.VirtualMemorySize64.ToString("#,#"),
                PagedMem = process.PagedMemorySize64.ToString("#,#"),
                PagedSystemMem = process.PagedSystemMemorySize64.ToString("#,#"),
                NonPagedSystemMem = process.NonpagedSystemMemorySize64.ToString("#,#"),
                Threads = process.Threads.Count.ToString(),
                ProcessorTime = process.TotalProcessorTime.ToString()
            };

            return JsonSerializeObject(memoryStat);
            //" - MaxWorkingSet: " + process.MaxWorkingSet.ToString("#,#") + // It is meaningless, it is always 1,413,120 
        }
        private string GetMemoryPeakStats()
        {
            var process = Process.GetCurrentProcess();
            var memoryStat = new MemoryStats
            {
                Info = "<span style=color:red>Peak Stats</span>",
                WorkingSet = process.PeakWorkingSet64.ToString("#,#"),
                VirtualMem = process.PeakVirtualMemorySize64.ToString("#,#"),
                PagedMem = process.PeakPagedMemorySize64.ToString("#,#"),
                Handles = process.HandleCount.ToString("#,#"),
                Modules = process.Modules.Count.ToString(),
                ProcessorAffinity = process.ProcessorAffinity.ToString()
            };

            return JsonSerializeObject(memoryStat);
        }

    </script>
</head>
<body>
    <style>
        body { margin: 5px 10px;}
        #LogsCon {
            width: 100%;
            height: 850px;
            overflow: auto;
        }

        #TblLogs {
            border-collapse: collapse;
            width: 100%;
        }


        #TblLogs th, #TblLogs td {
            border: solid 1px darkgray;
            padding: 3px;
        }

        #TblLogs th {
            position: sticky;
            top: 0;
            background-color: darkslategrey;
            color: white;
            font-size: 12px;
        }

        body {
            font: 11px Verdana;
        }

        .con {
            margin: 6px 0;
        }
    </style>

    <div id="LogsCon">
        <table id="TblLogs" class="scroll">
            <thead>
                <tr>
                    <th>Date/Time</th>
                    <th data-field="Info">Info</th>
                    <th data-field="GCTotal">GC Total</th>
                    <th data-field="WorkingSet">WorkingSet</th>
                    <th data-field="PrivateMem">PrivateMem</th>
                    <th data-field="VirtualMem">VirtualMem</th>
                    <th data-field="PagedMem">PagedMem</th>
                    <th data-field="PagedSystemMem">PagedSystemMem</th>
                    <th data-field="NonPagedSystemMem">NonPagedSystemMem</th>
                    <th data-field="Handles">Handles</th>
                    <th data-field="Modules">Modules</th>
                    <th data-field="Threads">Threads</th>
                    <th data-field="ProcessorTime">ProcessorTime</th>
                </tr>
            </thead>
            <tbody>
            </tbody>
        </table>
    </div>
    <div class="con" style="float: right; clear: both">
        <button id="btnClearLogs">Clear Logs</button>
    </div>
    <div class="con">
        <button id="btnForceGC">Force Garbage Collect</button>
        <button id="btnGetPeakMemoryStats">Get Peak Memory Stats</button>
    </div>
    <div class="con">
        Refresh Interval:
        <input type="text" id="txtInterval" value="10000" />
        ms.
    </div>

    <script>
        function scrollToBottom($elem) {
            var obj = $elem[0];
            obj.scrollTop = obj.scrollHeight;
        }

        var fieldNames;
        function GetFieldNames() {
            if (fieldNames)
                return fieldNames;
            fieldNames = $("#TblLogs > thead > tr > th[data-field]").map((i, elem) => $(elem).data("field"));
            return fieldNames;
        }
        function UpdateResult(data) {
            var $logs = $("#TblLogs > tbody");

            var fieldNames = GetFieldNames();
            var dateCellHtml = `<td>${new Date().toLocaleString()}</td>`;
            var cells = fieldNames.map((i, item) => `<td>${data[item] || ''}</td>`).get();
            var cellsHtml = cells.join("");
            $logs.append(`<tr>${dateCellHtml}${cellsHtml}</tr>`);
            scrollToBottom($("#LogsCon"));
        }
        function performAjax(reqData) {
            $.post("Memory.aspx", reqData, null, "json")
                .done(function (data) {
                    UpdateResult(data);
                }).fail(function (xhr) {
                    UpdateResult(xhr.status + " " + xhr.statusText);
                });
        }
        function GetMemoryStats() {
            performAjax({ op: "GetMemoryStats" });
        }
        function GetPeakMemoryStats() {
            performAjax({ op: "GetPeakMemoryStats" });
        }

        function ForceGC() {
            performAjax({ op: "ForceGC" });
        }

        var interval = null;
        function InitInterval() {
            if (interval != null) {
                clearInterval(interval);
            }

            var delay = parseInt($("#txtInterval").val(), 10);
            if (delay < 100)
                delay = 100;
            $("#txtInterval").val(delay);
            interval = setInterval(GetMemoryStats, delay);
        }

        GetMemoryStats();
        InitInterval();

        $("#txtInterval").on("change", InitInterval);
        $("#btnForceGC").on("click",
            function () {
                ForceGC();
            });
        $("#btnGetPeakMemoryStats").on("click",
            function () {
                GetPeakMemoryStats();
            });
        $("#btnClearLogs").on("click",
            function () {
                if (confirm("Clear logs?"))
                    $("#TblLogs > tbody").html("");
            });
    </script>
</body>
</html>
