A collection of ETL scripts designed to be run as scheduled tasks 
running hive queries on a remote machine retrieveing the results 
s
and importing them to a mysql database also on a remote machine.

# Compass

标签： 数据处理 BigData Game－Analyze 

---

Compass作为数据分析后台，主要基于Hadoop生态系统

```flow
st=>start: Start:>https://www.zybuluo.com
io=>inputoutput: verification
op=>operation: Your Operation
cond=>condition: Yes or No?
sub=>subroutine: Your Subroutine
e=>end

st->io->op->cond
cond(yes)->e
cond(no)->sub->io
```

