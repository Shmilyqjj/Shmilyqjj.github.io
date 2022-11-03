---
title: Iceberg数据湖探索与实践
author: 佳境
avatar: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/img/custom/avatar.jpg
authorLink: shmily-qjj.top
authorAbout: '你自以为的极限,只是别人的起点'
authorDesc: '你自以为的极限,只是别人的起点'
categories:
  - 技术
comments: true
tags:
  - Iceberg
  - 数据湖
keywords: Iceberg
description: Iceberg数据湖相关知识探索与实践
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/DataLake/Iceberg/Iceberg-cover.jpg
abbrlink: 38dd005e
date: 2022-10-31 10:10:00
---
# Iceberg数据湖探索与实践
## 概念引入--数据湖
* **数据湖是一种存储数据的方式**,用于组织不同数据结构.本质上是一种企业数据架构方法,物理实现上则是基于数据存储平台(例如Hadoop,OSS,S3等存储系统),**集中存储企业内海量的、多来源,多种类的数据,并支持对数据进行快速加工和分析**.
* **数据湖的主要思想是对企业中的所有数据进行统一存储**,从原始数据转换为用于报告、可视化、分析和机器学习等各种任务的目标数据.
* 数据湖中的数据包括结构化数据（关系数据库数据）,半结构化数据（CSV、XML、JSON等）,非结构化数据（电子邮件,文档,PDF）和二进制数据（图像、音频、视频）,从而形成一个容纳所有形式数据的集中式数据存储.


## Iceberg简介
**Iceberg是一种高性能的TableFormat(表格式),定义了数据、元数据的组织方式,支持在Spark、Trino、Flink、Hive及Impala等计算引擎中使用.**

### Iceberg特性
1. 真正的流批一体: 上游写入数据后下游立即可查,满足实时场景;Iceberg提供了流批读取和流批写入接口,用户可以在同一个流程同时处理流批数据,使得流批处理可以使用相同的存储模型,简化了ETL思路.
2. 支持异构计算和存储引擎: 存储上支持常见存储如HDFS以及各种对象存储(不与底层存储强绑定);计算上支持Flink,Spark,Presto,Hive等常见计算引擎.
3. Schema Evolution(模式演化): 支持无副作用地增(ADD)删(Drop)改(Update)列,改变列顺序(Reorder)以及重命名列(Rename),且代价很低(只涉及元数据操作,不存在数据重新读写操作)(Iceberg使用唯一ID定位列,新增列会分配新的ID,所以列不会错位)
4. Partition Evolution(分区演化): 在已有的表上改变分区策略时,之前的分区数据不会变且依然采用老的分区策略,新数据会采用新的分区策略.在Iceberg元数据里,两个分区策略相互独立.比如以前有个天分区表,现在业务需要小时分区,按Hive数仓的处理方式需要重新建表,但Iceberg表直接在原表上更改分区布局即可.
![alt](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/DataLake/Iceberg/Iceberg-1.png)
5. 支持隐藏分区: Iceberg的分区信息不需要人工维护,可以被隐藏起来.与Hive指定分区字段的方式不同,Iceberg的分区字段(分区策略)支持通过某字段计算出来,在建表或者修改分区策略之后, 新的数据会自动计算所属于的分区,查询时Iceberg会自动过滤不需要扫描的数据,避免了因用户SQL未指定分区过滤条件而导致的性能问题,让用户更专注业务逻辑而无需考虑分区字段过滤问题.(Iceberg分区信息和数据存储目录是相互独立开的,使得Iceberg表分区可以被修改,而且不涉及数据迁移;分区信息不存在HMS,减轻了HMS的压力)
6. 分区演化和隐藏分区使得业务可以方便地调整分区策略.
7. Time Travel: 可以查询历史某一时间点snapshot的数据,支持回滚到历史snapshot.
8. 支持事务(ACID): Iceberg提供了边读边写的能力,上游数据写入即可见,通过事务,保证了下游组件只能消费已经commit的数据,无法读到未提交的数据.支持添加删除更新数据.
9. 支持基于乐观锁的并发写: Iceberg基于乐观锁提供了多个程序并发写入的能力并且保证数据线性一致.(乐观创建metadata文件,提交更新会触发metadata原子交换,完成提交)
10. 文件级数据剪裁: Iceberg通过元数据来对查询进行高效过滤,Iceberg的元数据里面提供了每个数据文件的一些统计信息, 比如最大值, 最小值, Count计数等等. 因此, 查询SQL的过滤条件除了常规的分区, 列过滤, 甚至可以下推到文件级别, 大大加快了查询效率.
11. 支持多种底层存储格式如Parquet、Avro以及ORC等.


## Iceberg原理
### Iceberg元数据
![alt](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/DataLake/Iceberg/Iceberg-2.png)  
1.**DataFiles数据文件** 存放真实数据文件,由一个或多个ManifestFile跟踪

2.**MetadataFile文件** "*.metadata.json"文件,Iceberg表某时刻的状态,里面记录了表Schema,分区配置,表参数,snapshot记录以及这个时刻涉及到的所有的ManifestList.

3.**ManifestList清单列表** "snap-*.avro"文件,存储了构建快照的所有ManifestFile列表,每个ManifestFile在里面占一行,每行存储了ManifestFile路径,分区范围,增删文件信息,来为查询时提供过滤能力,提高性能.一个快照对应一个ManifestList文件.

4.**ManifestFile清单文件** 非snap开头的avro格式文件,包含了DataFiles列表,每行包含一个数据文件的详细描述(状态,路径,分区信息,列级别的统计信息,最大值最小值空值个数,文件大小,行数等),为查询时提供过滤能力,提高性能.

**HadoopCatalog与HiveCatalog表的目录结构**  
![alt](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/DataLake/Iceberg/Iceberg-3.png)  
差异:
1.HadoopCatalog表MetadataFile命名为v*.metadata.json,与HiveCatalog表ManifestList命名规范不同  
2.HadoopCatalog表通过version-hint.text记录最新快照ID,HiveCatalog通过HiveMetaStore记录最新metadata_location.  

**HadoopCatalog表元数据解析**  
```shell
# 查看avro文件内容
wget https://repo1.maven.org/maven2/org/apache/avro/avro-tools/1.11.1/avro-tools-1.11.1.jar
java -jar avro-tools-1.11.1.jar tojson xxx.avro
```
MetadataFile文件 v3.metadata.json
```json
{
  "format-version" : 1,
  "table-uuid" : "eeffbc08-9156-4a6f-8380-6138c6b67889",
  "location" : "hdfs://shmily:8020/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table",
  "last-updated-ms" : 1667357677633,
  "last-column-id" : 4,
  "schema" : {
    "type" : "struct",
    "schema-id" : 0,
    "fields" : [ {
      "id" : 1,
      "name" : "id",
      "required" : false,
      "type" : "long"
    }, {
      "id" : 2,
      "name" : "name",
      "required" : false,
      "type" : "string"
    }, {
      "id" : 3,
      "name" : "age",
      "required" : false,
      "type" : "int"
    }, {
      "id" : 4,
      "name" : "dt",
      "required" : false,
      "type" : "string"
    } ]
  },
  "current-schema-id" : 0,
  "schemas" : [ {
    "type" : "struct",
    "schema-id" : 0,
    "fields" : [ {
      "id" : 1,
      "name" : "id",
      "required" : false,
      "type" : "long"
    }, {
      "id" : 2,
      "name" : "name",
      "required" : false,
      "type" : "string"
    }, {
      "id" : 3,
      "name" : "age",
      "required" : false,
      "type" : "int"
    }, {
      "id" : 4,
      "name" : "dt",
      "required" : false,
      "type" : "string"
    } ]
  } ],
  "partition-spec" : [ {
    "name" : "dt",
    "transform" : "identity",
    "source-id" : 4,
    "field-id" : 1000
  } ],
  "default-spec-id" : 0,
  "partition-specs" : [ {
    "spec-id" : 0,
    "fields" : [ {
      "name" : "dt",
      "transform" : "identity",
      "source-id" : 4,
      "field-id" : 1000
    } ]
  } ],
  "last-partition-id" : 1000,
  "default-sort-order-id" : 0,
  "sort-orders" : [ {
    "order-id" : 0,
    "fields" : [ ]
  } ],
  "properties" : {
    "EXTERNAL" : "TRUE",
    "write.metadata.previous-versions-max" : "5",
    "bucketing_version" : "2",
    "write.metadata.delete-after-commit.enabled" : "true",
    "write.distribution-mode" : "hash",
    "storage_handler" : "org.apache.iceberg.mr.hive.HiveIcebergStorageHandler"
  },
  "current-snapshot-id" : 1244418053907939374,
  "refs" : {
    "main" : {
      "snapshot-id" : 1244418053907939374,
      "type" : "branch"
    }
  },
  "snapshots" : [ {
    "snapshot-id" : 7688152750730458585,
    "timestamp-ms" : 1667357628763,
    "summary" : {
      "operation" : "append",
      "added-data-files" : "1",
      "added-records" : "2",
      "added-files-size" : "1272",
      "changed-partition-count" : "1",
      "total-records" : "2",
      "total-files-size" : "1272",
      "total-data-files" : "1",
      "total-delete-files" : "0",
      "total-position-deletes" : "0",
      "total-equality-deletes" : "0"
    },
    "manifest-list" : "hdfs://shmily:8020/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table/metadata/snap-7688152750730458585-1-f0e6c6ca-51a7-42e6-b412-4036e27c7d98.avro",
    "schema-id" : 0
  }, {
    "snapshot-id" : 1244418053907939374,
    "parent-snapshot-id" : 7688152750730458585,
    "timestamp-ms" : 1667357677633,
    "summary" : {
      "operation" : "append",
      "added-data-files" : "1",
      "added-records" : "1",
      "added-files-size" : "1166",
      "changed-partition-count" : "1",
      "total-records" : "3",
      "total-files-size" : "2438",
      "total-data-files" : "2",
      "total-delete-files" : "0",
      "total-position-deletes" : "0",
      "total-equality-deletes" : "0"
    },
    "manifest-list" : "hdfs://shmily:8020/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table/metadata/snap-1244418053907939374-1-44671db7-02ca-47c1-a229-c7f62d8aa12f.avro",
    "schema-id" : 0
  } ],
  "snapshot-log" : [ {
    "timestamp-ms" : 1667357628763,
    "snapshot-id" : 7688152750730458585
  }, {
    "timestamp-ms" : 1667357677633,
    "snapshot-id" : 1244418053907939374
  } ],
  "metadata-log" : [ {
    "timestamp-ms" : 1667357528190,
    "metadata-file" : "hdfs://shmily:8020/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table/metadata/v1.metadata.json"
  }, {
    "timestamp-ms" : 1667357628763,
    "metadata-file" : "hdfs://shmily:8020/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table/metadata/v2.metadata.json"
  } ]
}
```

ManifestList清单列表文件 snap-7688152750730458585-1-f0e6c6ca-51a7-42e6-b412-4036e27c7d98.avro
```json
{"manifest_path":"hdfs://shmily:8020/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table/metadata/f0e6c6ca-51a7-42e6-b412-4036e27c7d98-m0.avro","manifest_length":6189,"partition_spec_id":0,"added_snapshot_id":{"long":7688152750730458585},"added_data_files_count":{"int":1},"existing_data_files_count":{"int":0},"deleted_data_files_count":{"int":0},"partitions":{"array":[{"contains_null":false,"contains_nan":{"boolean":false},"lower_bound":{"bytes":"20221011"},"upper_bound":{"bytes":"20221011"}}]},"added_rows_count":{"long":2},"existing_rows_count":{"long":0},"deleted_rows_count":{"long":0}}
```

ManifestFile清单文件 f0e6c6ca-51a7-42e6-b412-4036e27c7d98-m0.avro
```json
{"status":1,"snapshot_id":{"long":7688152750730458585},"data_file":{"file_path":"hdfs://shmily:8020/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table/data/dt=20221011/00000-0-hive_20221102105315_5bb17fc0-3092-4bed-8839-253f19117b6d-job_1667357081446_0001-00001.parquet","file_format":"PARQUET","partition":{"dt":{"string":"20221011"}},"record_count":2,"file_size_in_bytes":1272,"block_size_in_bytes":67108864,"column_sizes":{"array":[{"key":1,"value":55},{"key":2,"value":59},{"key":3,"value":93},{"key":4,"value":101}]},"value_counts":{"array":[{"key":1,"value":2},{"key":2,"value":2},{"key":3,"value":2},{"key":4,"value":2}]},"null_value_counts":{"array":[{"key":1,"value":0},{"key":2,"value":0},{"key":3,"value":0},{"key":4,"value":0}]},"nan_value_counts":{"array":[]},"lower_bounds":{"array":[{"key":1,"value":"\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000"},{"key":2,"value":"abc"},{"key":3,"value":"\u0018\u0000\u0000\u0000"},{"key":4,"value":"20221011"}]},"upper_bounds":{"array":[{"key":1,"value":"\u0002\u0000\u0000\u0000\u0000\u0000\u0000\u0000"},{"key":2,"value":"qjj"},{"key":3,"value":"\u0018\u0000\u0000\u0000"},{"key":4,"value":"20221011"}]},"key_metadata":null,"split_offsets":{"array":[4]},"sort_order_id":{"int":0}}}
```

**HiveCatalog表元数据解析**  
MetadataFile文件 00001-66c5832f-9d6d-4674-9a52-2aa6b8e29991.metadata.json 
```json
{
  "format-version" : 1,
  "table-uuid" : "5397c8ee-2b24-4eea-83ae-55e024ccd2c0",
  "location" : "hdfs://shmily:8020/user/hive/warehouse/iceberg_db.db/hive_iceberg_partitioned_table",
  "last-updated-ms" : 1665470339331,
  "last-column-id" : 4,
  "schema" : {
    "type" : "struct",
    "schema-id" : 0,
    "fields" : [ {
      "id" : 1,
      "name" : "id",
      "required" : false,
      "type" : "long"
    }, {
      "id" : 2,
      "name" : "name",
      "required" : false,
      "type" : "string"
    }, {
      "id" : 3,
      "name" : "age",
      "required" : false,
      "type" : "int"
    }, {
      "id" : 4,
      "name" : "dt",
      "required" : false,
      "type" : "string"
    } ]
  },
  "current-schema-id" : 0,
  "schemas" : [ {
    "type" : "struct",
    "schema-id" : 0,
    "fields" : [ {
      "id" : 1,
      "name" : "id",
      "required" : false,
      "type" : "long"
    }, {
      "id" : 2,
      "name" : "name",
      "required" : false,
      "type" : "string"
    }, {
      "id" : 3,
      "name" : "age",
      "required" : false,
      "type" : "int"
    }, {
      "id" : 4,
      "name" : "dt",
      "required" : false,
      "type" : "string"
    } ]
  } ],
  "partition-spec" : [ {
    "name" : "dt",
    "transform" : "identity",
    "source-id" : 4,
    "field-id" : 1000
  } ],
  "default-spec-id" : 0,
  "partition-specs" : [ {
    "spec-id" : 0,
    "fields" : [ {
      "name" : "dt",
      "transform" : "identity",
      "source-id" : 4,
      "field-id" : 1000
    } ]
  } ],
  "last-partition-id" : 1000,
  "default-sort-order-id" : 0,
  "sort-orders" : [ {
    "order-id" : 0,
    "fields" : [ ]
  } ],
  "properties" : {
    "engine.hive.enabled" : "true",
    "write.metadata.previous-versions-max" : "5",
    "bucketing_version" : "2",
    "write.metadata.delete-after-commit.enabled" : "true",
    "write.distribution-mode" : "hash",
    "storage_handler" : "org.apache.iceberg.mr.hive.HiveIcebergStorageHandler"
  },
  "current-snapshot-id" : 6283861985931247372,
  "refs" : {
    "main" : {
      "snapshot-id" : 6283861985931247372,
      "type" : "branch"
    }
  },
  "snapshots" : [ {
    "snapshot-id" : 6283861985931247372,
    "timestamp-ms" : 1665470339331,
    "summary" : {
      "operation" : "append",
      "added-data-files" : "2",
      "added-records" : "3",
      "added-files-size" : "2438",
      "changed-partition-count" : "2",
      "total-records" : "3",
      "total-files-size" : "2438",
      "total-data-files" : "2",
      "total-delete-files" : "0",
      "total-position-deletes" : "0",
      "total-equality-deletes" : "0"
    },
    "manifest-list" : "hdfs://shmily:8020/user/hive/warehouse/iceberg_db.db/hive_iceberg_partitioned_table/metadata/snap-6283861985931247372-1-825f6beb-3be7-485c-b338-8dec6068be94.avro",
    "schema-id" : 0
  } ],
  "snapshot-log" : [ {
    "timestamp-ms" : 1665470339331,
    "snapshot-id" : 6283861985931247372
  } ],
  "metadata-log" : [ {
    "timestamp-ms" : 1665470256700,
    "metadata-file" : "hdfs://shmily:8020/user/hive/warehouse/iceberg_db.db/hive_iceberg_partitioned_table/metadata/00000-d4b0dc94-f59f-4968-950c-31d22c2aab0d.metadata.json"
  } ]
}
```

ManifestList清单列表文件   snap-6283861985931247372-1-825f6beb-3be7-485c-b338-8dec6068be94.avro
```json
{"manifest_path":"hdfs://shmily:8020/user/hive/warehouse/iceberg_db.db/hive_iceberg_partitioned_table/metadata/825f6beb-3be7-485c-b338-8dec6068be94-m0.avro","manifest_length":6234,"partition_spec_id":0,"added_snapshot_id":{"long":6283861985931247372},"added_data_files_count":{"int":2},"existing_data_files_count":{"int":0},"deleted_data_files_count":{"int":0},"partitions":{"array":[{"contains_null":false,"contains_nan":{"boolean":false},"lower_bound":{"bytes":"20221010"},"upper_bound":{"bytes":"20221011"}}]},"added_rows_count":{"long":3},"existing_rows_count":{"long":0},"deleted_rows_count":{"long":0}}
```

ManifestFile清单文件 825f6beb-3be7-485c-b338-8dec6068be94-m0.avro
```json
{"status":1,"snapshot_id":{"long":6283861985931247372},"data_file":{"file_path":"hdfs://shmily:8020/user/hive/warehouse/iceberg_db.db/hive_iceberg_partitioned_table/data/dt=20221011/00000-0-shmily_20221011143858_89f7e99f-7227-4b19-9a44-b6807cf3b718-job_local1764035342_0002-00001.parquet","file_format":"PARQUET","partition":{"dt":{"string":"20221011"}},"record_count":2,"file_size_in_bytes":1272,"block_size_in_bytes":67108864,"column_sizes":{"array":[{"key":1,"value":55},{"key":2,"value":59},{"key":3,"value":93},{"key":4,"value":101}]},"value_counts":{"array":[{"key":1,"value":2},{"key":2,"value":2},{"key":3,"value":2},{"key":4,"value":2}]},"null_value_counts":{"array":[{"key":1,"value":0},{"key":2,"value":0},{"key":3,"value":0},{"key":4,"value":0}]},"nan_value_counts":{"array":[]},"lower_bounds":{"array":[{"key":1,"value":"\u0001\u0000\u0000\u0000\u0000\u0000\u0000\u0000"},{"key":2,"value":"abc"},{"key":3,"value":"\u0018\u0000\u0000\u0000"},{"key":4,"value":"20221011"}]},"upper_bounds":{"array":[{"key":1,"value":"\u0002\u0000\u0000\u0000\u0000\u0000\u0000\u0000"},{"key":2,"value":"qjj"},{"key":3,"value":"\u0018\u0000\u0000\u0000"},{"key":4,"value":"20221011"}]},"key_metadata":null,"split_offsets":{"array":[4]},"sort_order_id":{"int":0}}}
{"status":1,"snapshot_id":{"long":6283861985931247372},"data_file":{"file_path":"hdfs://shmily:8020/user/hive/warehouse/iceberg_db.db/hive_iceberg_partitioned_table/data/dt=20221010/00000-0-shmily_20221011143858_89f7e99f-7227-4b19-9a44-b6807cf3b718-job_local1764035342_0002-00002.parquet","file_format":"PARQUET","partition":{"dt":{"string":"20221010"}},"record_count":1,"file_size_in_bytes":1166,"block_size_in_bytes":67108864,"column_sizes":{"array":[{"key":1,"value":51},{"key":2,"value":53},{"key":3,"value":51},{"key":4,"value":59}]},"value_counts":{"array":[{"key":1,"value":1},{"key":2,"value":1},{"key":3,"value":1},{"key":4,"value":1}]},"null_value_counts":{"array":[{"key":1,"value":0},{"key":2,"value":0},{"key":3,"value":0},{"key":4,"value":0}]},"nan_value_counts":{"array":[]},"lower_bounds":{"array":[{"key":1,"value":"\u0003\u0000\u0000\u0000\u0000\u0000\u0000\u0000"},{"key":2,"value":"abc"},{"key":3,"value":"\u0018\u0000\u0000\u0000"},{"key":4,"value":"20221010"}]},"upper_bounds":{"array":[{"key":1,"value":"\u0003\u0000\u0000\u0000\u0000\u0000\u0000\u0000"},{"key":2,"value":"abc"},{"key":3,"value":"\u0018\u0000\u0000\u0000"},{"key":4,"value":"20221010"}]},"key_metadata":null,"split_offsets":{"array":[4]},"sort_order_id":{"int":0}}}
```

### Iceberg表类型  
当Iceberg添加了新特性但该新特性破坏了向前兼容性时,表的version会增加,以保证旧的表版本仍然可以兼容.
Iceberg当前有V1和V2两种表类型,建表时由property-version指定.
[Version 1: Analytic Data Tables 🔗](https://iceberg.apache.org/spec/#version-1-analytic-data-tables) 基于不可变文件格式管理的大型分析表
[Version 2: Row-level Deletes 🔗](https://iceberg.apache.org/spec/#version-2-row-level-deletes) 较Version 1添加了行级更新\删除能力;添加了Delete files以对现有数据文件中删除的行进行编码。Version2可实现删除或替换不可变数据文件中的单个行，而无需重写文件。

### Iceberg表数据类型  
| 数据类型 | 介绍 | 要求 |
| ---- | ---- | ---- |
| int | 32位有符号整形 | 可转为long |
| long | 64位有符号整形 | |
| float | 单精度浮点型 | 可转为double |
| double | 双精度浮点型 | |
| decimal(P,S) | 固定小数点类型数值 | 精度P,决定总位数;比例S,决定小数位数;P必须小于等于38 |
| date | 日期,不含时间和时区 | |
| time | 时间,不含日期和时区 | 以微妙存储 |
| timestamp | 不含时区的时间戳 | 以微妙存储 |
| timestamptz | 含时区的时间戳 | 以微妙存储 |
| string | 字符串,任意长度 | Encoded with UTF-8 |
| fixed(L) | 固定长度为L的字节数组 | |
| binary | 任意长度字节数组 | |
| struct<...> | 任意数据类型组成的结构体 | |
| list | 任意数据类型组成的List | |
| map<K,V> | 任意数据类型组成的键值对 | |

## Iceberg集成
### Iceberg与Hive集成
添加iceberg-hive-runtime-0.14.1.jar,libfb303-0.9.3.jar两个jar到$HIVE_HOME/auxlib下
添加**iceberg.engine.hive.enabled=true**参数到hive-site.xml

Hive创建Iceberg表
(Hive操作Iceberg支持多种Catalog，支持Hadoop、Hive(默认)、Custom、location_based_table几种管理方式)

1.**HiveCatalog**类型(表元数据信息使用HiveMetaStore来管理，依赖Hive):
```sql
-- 不设置Catalog类型时默认会使用HiveCatalog类型的Iceberg表
-- 示例1 非分区表
CREATE TABLE iceberg_db.hive_iceberg_table (
  id BIGINT,
  name STRING
)
STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
LOCATION '/user/hive/warehouse/iceberg_db.db/hive_iceberg_table'
TBLPROPERTIES (
 'write.distribution-mode'='hash',
 'write.metadata.delete-after-commit.enabled'='true',   -- (每次提交后是否删除旧元数据文件) 自动清理旧元数据 metadata.json 不能清理manifest和snapshot的avro文件
 'write.metadata.previous-versions-max'='5'  -- 保留的metadata.json数量
);
-- 示例2 分区表
CREATE TABLE iceberg_db.hive_iceberg_partitioned_table (
  id BIGINT,
  name STRING,
  age int
) partitioned by (dt string)
STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
TBLPROPERTIES (
 'write.distribution-mode'='hash',
 'write.metadata.delete-after-commit.enabled'='true',
 'write.metadata.previous-versions-max'='5'
);
-- 示例3 手动指定catalog名称,指定catalog类型为HiveCatalog类型并建表:
set iceberg.catalog.<catalog_name>.type=hive;  -- 设置catalog类型
CREATE TABLE iceberg_db.hive_iceberg_partitioned_table (
  id BIGINT,
  name STRING,
  age int
) partitioned by (dt string)
STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
TBLPROPERTIES (
'iceberg.catalog'='<catalog_name>',
 'write.distribution-mode'='hash',
 'write.metadata.delete-after-commit.enabled'='true',
 'write.metadata.previous-versions-max'='5'
);
```
HiveCatalog表在HMS中保存了很多Table Parameters信息,如current-schema,current-snapshot-xx,default-partition-spec,metadata_location,previous_metadata_location,snapshot-count等信息.

HiveCatalog表在Hive下存在的问题: 在Kerberos认证的HMS环境下,Hive客户端可以建表和查询,但无法inssert数据;可以使用beeline+hiveserver2进行Iceberg表的insert操作.

2.**HadoopCatalog**类型(元数据信息使用底层外部存储来管理)
```sql
set iceberg.catalog.<catalog_name>.type=hadoop;  -- 必须每次设置catalog类型
set iceberg.catalog.<catalog_name>.warehouse=hdfs://nameservice/user/iceberg/warehouse;  -- 必须每次设置warehouse存储路径
create external table iceberg_db.hadoop_iceberg_partitioned_table (
  id BIGINT,
  name STRING,
  age int
) partitioned by (dt string)
STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
LOCATION 'hdfs://nameservice/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_partitioned_table'  -- 路径必须是${iceberg.catalog.<catalog_name>.warehous}/${db_name}/${table_name}
tblproperties (
    'iceberg.catalog'='<catalog_name>',
    'write.distribution-mode'='hash',
    'write.metadata.delete-after-commit.enabled'='true',
    'write.metadata.previous-versions-max'='5'
);
```

3.**LocationBasedTable**(外部存储中**已经存在HadoopCatalog类型Iceberg表**的数据,将其**映射**到Hive表)
HDFS已经存在了Iceberg格式表的数据，我们可以指定tblproperties('iceberg.catalog'='location_based_table')和LOCATION,它会去指定的LOCATION路径下加载iceberg表数据.前提LOCATION下已经存在Iceberg格式表数据了.
建表时不需要加PARTITION BY,只需要加字段即可.
```sql
create external table iceberg_db.location_iceberg_partitioned_table (
  id BIGINT,
  name STRING,
  age INT,
  dt STRING
)
STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
LOCATION 'hdfs://nameservice/user/iceberg/warehouse/iceberg_db/location_iceberg_partitioned_table'
tblproperties ('iceberg.catalog'='location_based_table');
或
create table iceberg_db.location_iceberg_partitioned_table (
  id BIGINT,
  name STRING,
  age INT,
  dt STRING
)
STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
LOCATION 'hdfs://nameservice/user/iceberg/warehouse/iceberg_db/location_iceberg_partitioned_table'
tblproperties ('iceberg.catalog'='location_based_table');
```
推荐场景: 外部计算引擎均支持HadoopCatalog类型Iceberg表的情况下,比如Flink、Spark等引擎写入的数据，可以使用这种方式创建Hive表来打通Hive.
不推荐场景: 需要使用Trino分析该表.(因为Trino当前不支持HadoopCatalog类型Iceberg表)
注意: **外部存储上的Iceberg表,Catalog必须是HadoopCatalog类型的，否则无法读取数据。**如果是其他Catalog类型,表创建时会报错File does not exist: /table_path.../metadata/version-hint.text，表能创建成功，但查询结果为空。

### Iceberg与Flink集成  
Flink 1.14则下载iceberg-flink-runtime-1.14-0.14.1.jar 放入$FLINK_HOME/lib目录下
1. Flink DataStreamAPI集成Iceberg
写了几个案例:
Kafka数据通过Flink Datastream API写入Iceberg:
[**KafkaSinkHadoopCatalogIcebergTable**](https://github.com/Shmilyqjj/Shmily/blob/master/Flink/src/main/java/flink/study/streaming/sink/iceberg/KafkaSinkHadoopCatalogIcebergTable.java)
[**KafkaSinkHiveCatalogIcebergTable**](https://github.com/Shmilyqjj/Shmily/blob/master/Flink/src/main/java/flink/study/streaming/sink/iceberg/KafkaSinkHiveCatalogIcebergTable.java)
通过Flink Datastream API读取Iceberg:
[**HadoopCatalogIcebergTableSource**](https://github.com/Shmilyqjj/Shmily/blob/master/Flink/src/main/java/flink/study/streaming/source/iceberg/HadoopCatalogIcebergTableSource.java)
[**HiveCatalogIcebergTableSource**](https://github.com/Shmilyqjj/Shmily/blob/master/Flink/src/main/java/flink/study/streaming/source/iceberg/HiveCatalogIcebergTableSource.java)

2. Flink SQL集成Iceberg
**打通Kafka->Flink SQL->HadoopCatalog类型Iceberg表->Hive**
```sql
-- 启动flink集群：cd $FLINK_HOME ; bin/start-cluster.sh
-- 启动FlinkSQL Console：bin/sql-client.sh embedded shell
set execution.checkpointing.interval=10sec; -- 必须设置checkpoint  靠checkpoint提交更新数据到Iceberg
SET execution.runtime-mode = streaming;  -- 流式写
CREATE TABLE t_kafka_source (
    id BIGINT,
    name STRING,
    age INT,
    dt STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 'flink_topic1',  
    'scan.startup.mode' = 'latest-offset',
    'properties.bootstrap.servers' = 'cdh101:9092,cdh102:9092,cdh103:9092,cdh104:9092',
    'properties.group.id' = 'test',
    'format' = 'csv'
);
-- 1.写入Iceberg表[HadoopCatalog类型]
CREATE CATALOG hadoop_iceberg_catalog WITH (
  'type'='iceberg',  -- 创建HadoopCatalog类型Iceberg表在FlinkSQL中的Catalog
  'catalog-type'='hadoop',
  'warehouse'='hdfs://nameservice/user/iceberg/warehouse',
  'property-version'='1'
);
CREATE TABLE if not exists `hadoop_iceberg_catalog`.`iceberg_db`.`hadoop_iceberg_table_flink_sql` (
   id BIGINT,
   name STRING,
   age INT,
   dt STRING
) PARTITIONED BY (dt)
WITH('type'='ICEBERG',
'engine.hive.enabled'='true',  -- 支持hive查询(实测发现不加也没影响)
'read.split.target-size'='1073741824', -- 减少split数提升查询效率
'write.target-file-size-bytes'='134217728',
'write.format.default'='parquet',
'write.metadata.delete-after-commit.enabled'='true',
'write.metadata.previous-versions-max'='9',  
'write.distribution-mode'='hash');  -- 动态合并metadata
insert into hadoop_iceberg_catalog.iceberg_db.hadoop_iceberg_table_flink_sql select id,name,age,dt from t_kafka_source;
-- 2.FlinkSQL批式查询
SET execution.runtime-mode = batch;
select id,name,age,dt from `hadoop_iceberg_catalog`.`iceberg_db`.`hadoop_iceberg_table_flink_sql`;
-- 3.FlinkSQL流式查询
select id,name,age,dt from `hadoop_iceberg_catalog`.`iceberg_db`.`hadoop_iceberg_table_flink_sql` /*+ OPTIONS('streaming'='true', 'monitor-interval'='5s', 'start-snapshot-id'='3821550127947089987')*/ ;
-- 4.在Hive中创建Iceberg映射表[只针对HadoopCatalog类型表]
create external table iceberg_db.hadoop_iceberg_table_flink_sql (
  id BIGINT,
  name STRING,
  age INT,
  dt STRING
)
STORED BY 'org.apache.iceberg.mr.hive.HiveIcebergStorageHandler'
LOCATION 'hdfs://nameservice/user/iceberg/warehouse/iceberg_db/hadoop_iceberg_table_flink_sql'
tblproperties ('iceberg.catalog'='location_based_table');
-- 5.HiveSQL查询(能查到实时最新数据)
select * from iceberg_db.hadoop_iceberg_table_flink_sql; 
```

**打通Kafka->Flink SQL->HiveCatalog类型Iceberg表->Hive/Trino**
```sql
-- 写入Iceberg表[HiveCatalog类型]
-- 启动flink集群：cd $FLINK_HOME ; bin/start-cluster.sh
-- 启动FlinkSQL Console：bin/sql-client.sh embedded -j iceberg-flink-runtime-1.13-0.14.0.jar -j  /opt/cloudera/parcels/CDH/jars/hive-metastore-2.1.1-cdh6.3.1.jar -j /opt/cloudera/parcels/CDH/jars/libthrift-0.9.3.jar -j /opt/cloudera/parcels/CDH/jars/hive-common-2.1.1-cdh6.3.1.jar -j /opt/cloudera/parcels/CDH/jars/hive-serde-2.1.1-cdh6.3.1.jar -j /opt/cloudera/parcels/CDH/jars/libfb303-0.9.3.jar -j /opt/cloudera/parcels/CDH/jars/hive-shims-common-2.1.1-cdh6.3.1.jar shell
set execution.checkpointing.interval=10sec; -- 必须设置checkpoint  靠checkpoint提交更新数据到Iceberg
SET execution.runtime-mode = streaming;  -- 流式写
CREATE TABLE t_kafka_source (
    id BIGINT,
    name STRING,
    age INT,
    dt STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 'flink_topic1',  
    'scan.startup.mode' = 'latest-offset',
    'properties.bootstrap.servers' = 'cdh101:9092,cdh102:9092,cdh103:9092,cdh104:9092',
    'properties.group.id' = 'test',
    'format' = 'csv'
);
CREATE CATALOG hive_iceberg_catalog WITH (
  'type'='iceberg',
  'catalog-type'='hive',
  'uri'='thrift://cdh101:9083,thrift://cdh103:9083',
  'clients'='5',
  'property-version'='1',
  'warehouse'='hdfs://nameservice/user/iceberg/warehouse',
  'hive-conf-dir'='/etc/ecm/hive-conf'   -- 如果hive是kerberos认证的,必须要加hive-conf-dir参数,非kerberos集群可忽略
);
CREATE TABLE if not exists `hive_iceberg_catalog`.`iceberg_db`.`hive_iceberg_table_flink_sql` (
   id BIGINT,
   name STRING,
   age INT,
   dt STRING
) PARTITIONED BY (dt)
WITH('type'='ICEBERG',
'engine.hive.enabled'='true',
'read.split.target-size'='1073741824',
'write.target-file-size-bytes'='134217728',
'write.format.default'='parquet',
'write.metadata.delete-after-commit.enabled'='true',
'write.metadata.previous-versions-max'='9',  
'write.distribution-mode'='hash');
insert into hive_iceberg_catalog.iceberg_db.hive_iceberg_table_flink_sql select id,name,age,dt from t_kafka_source;
```
写入HiveCatalogIceberg表后，在Hive可以直接看到并查询表iceberg_db.hive_iceberg_table_flink_sql.
也可以先在hive创建表,再Flink写入,均正常.
Trino中也可以直接看到并查询该表.

3. StreamPark集成Iceberg(基于HiveCatalog)
StreamPark是基于Flink SQL的流式计算平台.在StreamPark上可以很方便地开发实时操作Iceberg的Flink任务.
环境: Hadoop 3.2.1 + Hive 3.1.2 + Iceberg 0.14.1 + Flink 1.14.5 + StreamPark 1.2.4 + OSS
FlinkSQL编写:
```sql
CREATE CATALOG hive_iceberg_catalog WITH (
  'type'='iceberg',
  'catalog-type'='hive',
  'uri'='thrift://thrift-host:9083',
  'clients'='5',
  'property-version'='1',
  'warehouse'='oss://bucket_name/data/iceberg/warehouse',
  'hive-conf-dir'='/etc/ecm/hive-conf'
);
-- Kafka source table
CREATE TABLE t_kafka_source (
    id BIGINT,
    name STRING,
    age INT,
    dt STRING
) WITH (
    'connector' = 'kafka',
    'topic' = 't_qjj_flink_test',  
    'scan.startup.mode' = 'latest-offset',
    'properties.bootstrap.servers' = 'broker1:9092,broker2:9092,broker3:9092',
    'properties.group.id' = 'test',
    'format' = 'csv'
);
-- Iceberg target table
CREATE TABLE IF NOT EXISTS `hive_iceberg_catalog`.`iceberg_db`.`hive_krb_iceberg_table_flink_sql` (
   id BIGINT,
   name STRING,
   age INT,
   dt STRING
) PARTITIONED BY (dt)
WITH('type'='ICEBERG',
'engine.hive.enabled'='true',
'read.split.target-size'='1073741824',
'write.target-file-size-bytes'='134217728',
'write.format.default'='parquet',
'write.metadata.delete-after-commit.enabled'='true',
'write.metadata.previous-versions-max'='10',  
'write.distribution-mode'='hash');
-- Insert data
insert into hive_iceberg_catalog.iceberg_db.hive_krb_iceberg_table_flink_sql select id,name,age,dt from t_kafka_source;
```
依赖jar:
```xml
  <dependency>
    <groupId>org.apache.iceberg</groupId>
    <artifactId>iceberg-flink-runtime-1.14</artifactId>
    <version>0.14.1</version>
  </dependency>
  <dependency>
    <groupId>org.apache.hive</groupId>
    <artifactId>hive-metastore</artifactId>
    <version>3.1.2</version>
  </dependency>
  <dependency>
    <groupId>org.apache.thrift</groupId>
    <artifactId>libthrift</artifactId>
    <version>0.9.3</version>
  </dependency>
  <dependency>
    <groupId>org.apache.thrift</groupId>
    <artifactId>libfb303</artifactId>
    <version>0.9.3</version>
  </dependency>
  <dependency>
    <groupId>org.apache.hive</groupId>
    <artifactId>hive-common</artifactId>
    <version>3.1.2</version>
  </dependency>
  <dependency>
    <groupId>org.apache.hive</groupId>
    <artifactId>hive-serde</artifactId>
    <version>3.1.2</version>
  </dependency>
  <dependency>
    <groupId>org.apache.hive.shims</groupId>
    <artifactId>hive-shims-common</artifactId>
    <version>3.1.2</version>
  </dependency>
  <dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-connector-kafka_2.12</artifactId>
    <version>1.14.5</version>
  </dependency>
  <dependency>
    <groupId>commons-cli</groupId>
    <artifactId>commons-cli</artifactId>
    <version>1.3.1</version>
  </dependency>
```
可能出现的异常:
```err
Exception in thread "main" java.lang.NoSuchMethodError: org.apache.commons.cli.Option.builder(Ljava/lang/String;)Lorg/apache/commons/cli/Option$Builder;
        at org.apache.flink.runtime.entrypoint.parser.CommandLineOptions.<clinit>(CommandLineOptions.java:27)
```
原因: streamx在下载hive依赖时,下载了它的子依赖,且hive使用的commons-cli与streamx使用的commons-cli版本不一致,导致jar冲突.  
解决: 每次build后手动删除hdfs dfs -rm -f hdfs://ns/streamx/workspace/项目ID/lib/commons-cli-1.2.jar


### Iceberg与Trino集成
Trino整合Iceberg需要配置$TRINO_HOME/etc/catalog/iceberg.properties内容如下:
```
connector.name=iceberg
iceberg.file-format=PARQUET
hive.metastore.service.principal=hive/metastore-server-ip@realm-name 
hive.metastore.authentication.type=KERBEROS
hive.metastore.uri=thrift://metastore-server-ip:9083,metastore-server-ip-bk:9083
hive.metastore.client.principal=principal-in-hive-keytab
hive.metastore.client.keytab=/path/to/hive.keytab
hive.config.resources=/etc/ecm/hadoop-conf/core-site.xml, /etc/ecm/hadoop-conf/hdfs-site.xml
iceberg.compression-codec=SNAPPY
```
若需要其支持外部存储例如oss,则需要将jindo-core-4.3.0.jar和jindo-sdk-4.3.0.jar两个jar拷贝到$TRINO_HOME/plugin/iceberg/和$TRINO_HOME/plugin/hive/以兼容外部存储.

Trino当前仅支持HiveCatalog类型的Iceberg表,不支持HadoopCatalog类型Iceberg表.如果查询的是HadoopCatalog,location_based_table,Custome类型的Iceberg表会报错:Table is missing [metadata_location] property: iceberg_db.iceberg_table

### Iceberg与Spark集成
......


## Iceberg表管理维护
### metadata数控制
在Iceberg中,每次触发事务提交都会生成一个metadata.json,应当避免metadata文件无限增长,可以在建表时指定如下参数:
```conf
'write.metadata.delete-after-commit.enabled'='true' # 发生commit后,是否删除比较旧的metadata文件
'write.metadata.previous-versions-max'='50' # 保留的最大历史metadata文件数量,超过该历史版本数量的老的metadata文件会被删除
```

### 清理过期snapshot
清理Iceberg表过期快照的Demo
[**ClearExpiredSnapshots**](https://github.com/Shmilyqjj/Shmily/blob/master/Iceberg/src/main/scala/top/shmily_qjj/iceberg/table/maintenance/ClearExpiredSnapshots.scala)

### 数据文件重写
流式数据写入可能会产生大量小的数据文件,Iceberg提供了rewriteDataFiles(Compaction)操作,可以定期合并小文件,提高查询性能.

## 对比Hudi和DeltaLake
| 对比维度\技术 | Iceberg | Hudi | DeltaLake |
| ---- | ---- | ---- | ---- |
| 数据管理 | 通过metadata文件管理 | 通过metadata文件管理 | 通过metadata文件管理 |
| 使用场景 | 流批一体,高性能分析与可靠数据管理 | 流批一体,Upsert场景 | 流批一体,融合Spark生态 |
| ACID | 支持 | 支持 | 支持 |
| ACID隔离级别 | Write Serialization(写串行执行) | Snapshot Isolation(写数据若无交集则并发写,否则串行) | Serialization(读写都必须串行)/Write Serialization/Snapshot Isolation |
| Schema演化 | 支持 | 支持 | 支持 |
| 数据操作 | 支持Update/Delete | 支持Upsert/Delete | 支持Update/Delete/Merge |
| 流式读 | 支持 | 支持 | 支持 |
| 流式写 | 支持 | 支持 | 支持 |
| 并发控制 | 乐观 | 乐观 | 乐观 |
| 文件清理 | 手动 | 自动 | 手动 |
| Compaction | 手动 | 自动 | 手动 |
| 外部依赖 | 完全解耦 | 依赖Spark | 依赖Spark |
| CopyOnWrite | 支持 | 支持 | 支持 |
| MergeOnRead | v2表支持,v1表不支持 | 支持 | 不支持 |
| 字段加密 | v3表计划支持 | 不支持 | 不支持 |

## 参考  
[Apache Iceberg](https://iceberg.apache.org/docs/latest)  
[Iceberg概述](https://zhuanlan.zhihu.com/p/429898023)  
[深度对比 Delta、Iceberg 和 Hudi 三大开源数据湖方案](https://cloud.tencent.com/developer/article/1936522)