public class ChainingSampleQueueable1 extends AbstractQueueable {


  public ChainingSampleQueueable1(){
    super('ChainingSampleQueueable1',true);
  }

  protected override void work() {
    AbstractChainTest.log(this);
  }
}