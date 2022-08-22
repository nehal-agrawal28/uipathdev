public class ChainingSampleQueueable2 extends AbstractQueueable {

  public ChainingSampleQueueable2(){
    super('ChainingSampleQueueable2',true);
  }

  protected override void work() {
    AbstractChainTest.log(this);
  }
}