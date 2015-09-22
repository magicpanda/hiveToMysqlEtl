# Compass

标签： 数据处理 BigData Game－Analyze ETL

[![Screen Preview](./Compass.png)](./Compass.png)
## 目录
[TOC]

## 概述
----------
Compass可以译为罗盘或者指南针，主要用来指引方向。而我们所有构建的数据分析平台也是如此，本平台主旨为游戏提供数据分析服务，方便快捷的获得直观准确的数据，从而可以更具针对性的对产品做出优化，提高产品质量。

从技术层面，系统主要基于Hadoop生态系统，Node.js，以及关系型数据库Mysql等技术构建而成。
从组件层面，系统包括：
 1. Track Service
 2. Compass BI@Report
 3. Compass ETL
 4. Hadoop Ecosystem 

##组件
###Track Service
-------------
Track Service 是一个基于Node.js的http服务器，主要用于用户行为所产生数据的收集，处理以及汇总等工作。

Track数据主要分为两大部分:

- 用户状态
  用户状态主要存储在Mysql关系型数据库中，只保存用户最新的状态,如User,User_Pay等数据.
- 事件流水
  ~~事件流水以**文本**的形式保存，使用log4js对日志进行纪录(在数据量比较小的时候,同时纪录在Mysql中,方便BI人员查询)。~~

    事件流水使用Flume组件实时传输至HDFS中.(在数据量比较小的时候,同时纪录在Mysql中,方便BI人员查询)。

  格式为:
```csv
id=291728A8CDDE4DCE9616157C16E3DE11,fbid=291728A8CDDE4DCE9616157C16E3DE11,action=levelDetail,time=1441695596,level=109,v1=3,v2=,v3=,v4=,v5=,v6=,v7=,v8=,ver=3.9,confVersion=30800
```

或者简单记录为：

```csv
1004,1f239b861f50482c8fd0356d9fa478db,1f239b861f50482c8fd0356d9fa478db,gotEnergy,1441658484000,12,1,3,,,,,,,3.7,30711
```
###Compass BI@Report
-------------
Compass BI@Report做为业务数据的展示系统，主要面向策划，运营等需要根据业务数据做出决策的各类人员。

本系统集成了多个应用的基础数据报表，以及针对业务数据各个维度的数据刻画报表。

Compass BI@Report主要使用Node.js,AngularJS,BootStrap，HighCharts等技术构建。

###Compass ETL
-------------
Compass ETL(ETL，是英文 Extract-Transform-Load的缩写)，系统主要实现将数据从来源端经过抽取（extract）、转换（transform）、最后加载（load）至目的端的过程。

ETL是构建数据仓库的重要一环，用户从数据源抽取出所需的数据，经过数据清洗,最终按照预先定义好的数据仓库模型，将数据加载到数据仓库中去。

Compass ETL 会根据不同应用，不同数据需求，定期调度执行ETL任务，将异构数据整理为数据仓库(Mysql)中的可查询数据。下边分别说明ETL包含的内容：

####Extract

在系统中，数据来源端为[Track Service](#TrackService)中的**用户状态**和**事件流水**。

Compass ETL系统会调用Apache的开源组件Sqoop，将用户状态从Mysql中导入至Hive的外部表中，而事件流水则使用Apache组件flume进行实时传输。

经过上边的步骤，会将**用户状态**和**事件流水**这两种异构数据统一为可以使用Hive进行查询的Hadoop生态系统中的HDFS数据。

接下来，Compass ETL会调用Hive的Beeline接口，对Hive表中的数据进行查询，并将结果存储为csv格式的中间结果。

####Transform
在Hive的HQL产生的csv中间结果中，存在一系列的噪点数据，这些数据会影响到数据结果分析的准确性。需要将这些数据清洗掉。系统中，每种业务数据的ETL都可以自定义数据清洗逻辑，如下为DAU业务模块的数据清洗逻辑：
```Javascript
DauETL.transformData = function (csvFile, callback) {
    console.info(module.exports.name + " Begin to transformData......");
    fs.readFile(__dirname + "/" + csvFile, "utf-8", function (err, data) {
        if (err) {
            console.log(err);
            callback(err, null);
            return;
        }
        csv.parse(data, function (err, data) {
            csv.transform(data, function (data) {
                return data.map(function (value) {
                    return value.toUpperCase()
                });
            }, function (err, data) {
                console.info(module.exports.name + " transformData end.");
                callback(null, null);
            });
        });
    });
};
```
除此之外，还可以对已经存在在数据仓库中的数据，做定期的更新和处理。例如，每天都会更新前14天的DAU数据，防止用户在某些情况下，日志延迟发送而造成的数据不准确的情况。
如下程序为，预处理数据仓库中需要更新的数据：
```Javascript
DauETL.preProcessWareHouseData = function (etlJob, callback) {
    console.info(module.exports.name + " Begin to preProcessWareHouseData......");
    var sql = 'delete from '+ "app" + etlJob.appid + "." + etlJob.tablename + ' where date >= ? and date <= ? ';
    db.query(sql, [DateFromDay, DateYesterday], function (err, result) {
        if (err) {
            console.info(module.exports.name + " preProcessWareHouseData failed." + err.toString());
        } else {
            console.info(module.exports.name + " preProcessWareHouseData success.");
        }
        callback(null, result);
    });
};
```


####Load
在经过数据抽取，清洗以及数据仓库的预处理之后，讲所得到的最终结果，load到数据库当中，如下边的代码：
```Javascript
DauETL.loadDataToWarehouse = function (csvFileName, etlJob, callback) {
    console.info(module.exports.name + " Begin to loadDataToWarehouse......");
    var sql = "LOAD DATA LOCAL INFILE '" + __dirname + "/" + csvFileName + "' REPLACE  INTO TABLE " + "app" + etlJob.appid + "." + etlJob.tablename + " FIELDS TERMINATED BY ','";
    db.query(sql, function (err, result) {
        if (err) {
            console.info(module.exports.name + " loadDataToWarehouse failed." + err.toString());
        } else {
            console.info(module.exports.name + " loadDataToWarehouse success.");
        }
        callback(null, result);
    });
};
```

###Hadoop Ecosystem
-------------
主要基于Cloudera 公司的Cloudera Manager，对大数据处理的系统进行部署和管理。目前主要使用以下组件：

 - HDFS
Apache Hadoop 分布式文件系统 (HDFS) 是 Hadoop 应用程序使用的主要存储系统.
HDFS创建多个数据块副本并将它们分布在整个群集的计算主机上，以启用可靠且极其快速的计算功能。
 - MapReduce
Apache Hadoop MapReduce 支持对整个群集中的大型数据集进行分布式计算（需要 HDFS）.
 - Hive
Hive 是一种数据仓库系统，提供名为 HiveQL 的 SQL 类语言.
 - Hue
Hue 是与Apache Hadoop生态系统一起配合使用的图形用户界面（需要 HDFS、MapReduce 和 Hive）.
 - Flume
Flume 从几乎所有来源收集数据并将这些数据聚合到永久性存储（如 HDFS）中.
 - Sqoop 2
Sqoop 是一个设计用于在 Apache Hadoop 和结构化数据存储（如关系数据库）之间高效地传输大批量数据的工具。Cloudera Manager 支持的版本为 Sqoop 2.
 - ZooKeeper
Apache ZooKeeper 是用于维护和同步配置数据的集中服务.
 - Oozie
Oozie 是群集中管理数据处理作业的工作流协调服务。
 ~~- HBase
Apache HBase 提供对大型数据集的随机、实时的读/写访问权限（需要 HDFS 和 ZooKeeper）.~~


