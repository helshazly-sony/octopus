package main.java;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

import java.nio.ByteBuffer;
import java.util.ArrayList;

import org.apache.arrow.flight.Action;
import org.apache.arrow.flight.ActionType;
import org.apache.arrow.flight.CallStatus;
import org.apache.arrow.flight.Criteria;
import org.apache.arrow.flight.FlightDescriptor;
import org.apache.arrow.flight.FlightInfo;
import org.apache.arrow.flight.FlightProducer;
import org.apache.arrow.flight.FlightStream;
import org.apache.arrow.flight.Location;
import org.apache.arrow.flight.PutResult;
import org.apache.arrow.flight.Result;
import org.apache.arrow.flight.Ticket;
import org.apache.arrow.memory.BufferAllocator;
import org.apache.arrow.util.AutoCloseables;
import org.apache.arrow.vector.VectorSchemaRoot;
import org.apache.arrow.vector.VectorUnloader;

/**
 * A FlightProducer that hosts an in memory store of Arrow buffers.
 */
public class ArrowFlightServer implements FlightProducer, AutoCloseable {

	private final ConcurrentMap<FlightDescriptor, Dataset> datasets = new ConcurrentHashMap<>();
	private final BufferAllocator allocator;
	private Location location;

	/**
	 * Constructs a new instance.
	 *
	 * @param allocator The allocator for creating new Arrow buffers.
	 * @param location The location of the storage.
	 */
	public ArrowFlightServer(BufferAllocator allocator, Location location) {
		super();
		this.allocator = allocator;
		this.location = location;
	}

	/**
	 * Update the location after server start.
	 *
	 * <p>Useful for binding to port 0 to get a free port.
	 */
	public void setLocation(Location location) {
		this.location = location;
	}

	@Override
	public void getStream(CallContext context, Ticket ticket,
			ServerStreamListener listener) {
		getStream(ticket).sendTo(allocator, listener);
	}

	/**
	 * Returns the appropriate stream given the ticket (streams are indexed by path and an ordinal).
	 */
	public Stream getStream(Ticket t) {
	        System.out.println("hahaha");
		StreamTicket st = StreamTicket.from(t);
		FlightDescriptor d = FlightDescriptor.path(st.getPath());
		System.out.println(d.toString());

		Dataset ds = datasets.get(d);
		if (ds == null) {
			throw new IllegalStateException("Unknown Ticket!");
		}
                 
		System.out.println(d.toString());
		System.out.println(st.getOrdinal());
		Stream stream = ds.getStream(st);
                System.out.println("lol");
		return stream;
	}

	@Override
	public void listFlights(CallContext context, Criteria criteria, StreamListener<FlightInfo> listener) {
		try {
			for (Dataset ds : datasets.values()) {
				listener.onNext(ds.getFlightInfo(location));
			}
			listener.onCompleted();
		} catch (Exception ex) {
			listener.onError(ex);
		}
	}

	@Override
	public FlightInfo getFlightInfo(CallContext context, FlightDescriptor descriptor) {
		Dataset ds = datasets.get(descriptor);
		if (ds == null) {
			throw new IllegalStateException("Unknown descriptor.");
		}

		return ds.getFlightInfo(location);
	}

	@Override
	public Runnable acceptPut(CallContext context,
			final FlightStream flightStream, final StreamListener<PutResult> ackStream) {
		return () -> {
			Stream.StreamCreator creator = null;
			boolean success = false;
			try (VectorSchemaRoot root = flightStream.getRoot()) {
				final Dataset ds = datasets.computeIfAbsent(
						flightStream.getDescriptor(),
						t -> new Dataset(allocator, t, flightStream.getSchema(), flightStream.getDictionaryProvider()));

				creator = ds.addStream(flightStream.getSchema());

				VectorUnloader unloader = new VectorUnloader(root);
				while (flightStream.next()) {
					ackStream.onNext(PutResult.metadata(flightStream.getLatestMetadata()));
					creator.add(unloader.getRecordBatch());
				}
				// Closing the stream will release the dictionaries
				flightStream.takeDictionaryOwnership();
				creator.complete();
				success = true;
			} finally {
				if (!success) {
					creator.drop();
				}
			}

		};

	}

	@Override
	public void doAction(CallContext context, Action action,
			StreamListener<Result> listener) {
		switch (action.getType()) {
		case "drop": {
			// not implemented.
			ByteBuffer byteBuffer = ByteBuffer.wrap(action.getBody());
			int ordinal = byteBuffer.getInt();
	        byte[] descriptionBytes = new byte[byteBuffer.remaining()];
	        byteBuffer.get(descriptionBytes);
	        String flightDescription = new String(descriptionBytes);
			
	        byte[] result;
	        if(dropStream(flightDescription, ordinal)) {
	        	result = "Action executed successfully!".getBytes();
	        } else {
	        	result = "Failure!".getBytes();
	        }
	        
			listener.onNext(new Result(result));
			listener.onCompleted();
			break;
		}
		default: {
			listener.onError(CallStatus.UNIMPLEMENTED.toRuntimeException());
		}
		}
	}

	public boolean dropStream(String fd, int ordinal) {
                ArrayList<String> paths = new ArrayList<String>();
        	paths.add(fd);
		FlightDescriptor d = FlightDescriptor.path(paths);
		System.out.println("Ordinal: " + ordinal);
		System.out.println("Closing stream of " + fd);
		try{
		   try(Dataset ds = datasets.remove(d)) {
		      ds.close();
	           }
		} catch(Exception e){
		  System.out.println(e);
		  return false;
		}

		try{
		   allocator.close();
                   this.close();
		} catch (Exception e){
		   System.out.println("ho");
		   System.out.println(e);
		}
                paths.clear();
        
		return true;
	}

	@Override
	public void listActions(CallContext context,
			StreamListener<ActionType> listener) {
		listener.onNext(new ActionType("get", "pull a stream. Action must be done via standard get mechanism"));
		listener.onNext(new ActionType("put", "push a stream. Action must be done via standard put mechanism"));
		listener.onNext(new ActionType("drop", "delete a flight. Action body is a JSON encoded path."));
		listener.onCompleted();
	}

	@Override
	public void close() throws Exception {
		AutoCloseables.close(datasets.values());
		datasets.clear();
	}

}
