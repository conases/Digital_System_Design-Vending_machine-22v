#include "Vboard_model.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <sstream>
#include <string>
#include <memory>
#include <cstdint>
int main(int argc,char** argv){
 auto ctx=std::make_unique<VerilatedContext>();ctx->commandArgs(argc,argv);
 ctx->traceEverOn(true);auto m=std::make_unique<Vboard_model>(ctx.get());
 auto trace=std::make_unique<VerilatedVcdC>();
 bool tracing=argc==3 && std::string(argv[1])=="--trace";
 if(tracing){m->trace(trace.get(),99);trace->open(argv[2]);}
 uint64_t cycles=0,event_id=0;std::string line;
 m->CLOCK_50=0;m->KEY=15;m->SW=0;m->eval();
 while(std::getline(std::cin,line)){
  uint64_t n;unsigned key,sw;std::istringstream in(line);
  if(!(in>>n>>key>>sw)||n>50000000||key>15||sw>8191){std::cout<<"{\"error\":\"invalid model command\"}"<<std::endl;continue;}
  m->KEY=key;m->SW=sw;
  std::ostringstream events;bool first=true;uint64_t event_count=0;
  auto event=[&](const char* kind,unsigned value){
   ++event_count;++event_id;
   if(event_count>10000)return;
   if(!first)events<<",";first=false;
   events<<"{\"id\":"<<event_id<<",\"cycle\":"<<cycles<<",\"kind\":\""<<kind<<"\",\"value\":"<<value<<"}";
  };
  unsigned previous_led=m->LEDG,previous_balance=m->balance;
  for(uint64_t i=0;i<n;++i){
   m->CLOCK_50=0;m->eval();ctx->timeInc(10);if(tracing)trace->dump(ctx->time());
   m->CLOCK_50=1;m->eval();ctx->timeInc(10);++cycles;if(tracing)trace->dump(ctx->time());
   if(m->issue)event("issue",m->balance);
   if(m->LEDG!=previous_led){event("LEDG",m->LEDG);previous_led=m->LEDG;}
   if(m->balance!=previous_balance){event("balance",m->balance);previous_balance=m->balance;}
  }
  m->eval();
  std::cout<<"{\"cycle\":"<<cycles<<",\"time_ns\":"<<ctx->time()
   <<",\"key\":"<<key<<",\"sw\":"<<sw<<",\"balance\":"<<unsigned(m->balance)
   <<",\"state\":"<<unsigned(m->state)<<",\"count6\":"<<unsigned(m->count6)<<",\"count7\":"<<unsigned(m->count7)
   <<",\"ledg\":"<<unsigned(m->LEDG)<<",\"ledr\":"<<unsigned(m->LEDR)
   <<",\"ready\":"<<unsigned(m->ready)<<",\"pending\":"<<unsigned(m->pending)<<",\"ce\":"<<unsigned(m->ce)
   <<",\"hex\":["<<unsigned(m->HEX0)<<","<<unsigned(m->HEX1)<<","<<unsigned(m->HEX2)<<","<<unsigned(m->HEX3)<<","<<unsigned(m->HEX4)<<",null,"<<unsigned(m->HEX6)<<","<<unsigned(m->HEX7)
   <<"],\"events\":["<<events.str()<<"],\"event_count\":"<<event_count<<",\"events_truncated\":"<<(event_count>10000?"true":"false")<<"}"<<std::endl;
 }
 m->final();if(tracing)trace->close();
}
