public class NoOpSkipToNext extends AbstractQueueable {

    public NoOpSkipToNext() {
        super('NoOpSkipToNext');
    }

    protected override void work() {
        //NOOP
    }
}